package com.rmgflow.ta.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.ta.dto.RecordActualDateRequest;
import com.rmgflow.ta.dto.TaMilestoneResponse;
import com.rmgflow.ta.entity.TaMilestone;
import com.rmgflow.ta.entity.TaMilestoneStatus;
import com.rmgflow.ta.entity.TaTemplate;
import com.rmgflow.ta.entity.TaTemplateMilestone;
import com.rmgflow.ta.repository.TaMilestoneRepository;
import com.rmgflow.ta.repository.TaTemplateMilestoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Document 8.7/9.5/10.3/A15/A16: instantiates milestones from a resolved template
 * at order confirmation, derives status at read-time, and implements the delay
 * cascade automation (A16) — the single highest-value automation in the system
 * per Document 10.3/13.1's own framing, so it gets built in Phase 7 rather than
 * deferred to the later notification phases.
 */
@Service
@RequiredArgsConstructor
public class TaMilestoneService {

    /** Document 9.5: default critical-delay threshold in days (configurable later via org settings). */
    private static final int CRITICAL_DELAY_THRESHOLD_DAYS = 3;
    /** Document 13.1: a hard depth cap on the cascade, defensive against any accidental
     * dependency cycle a template might (incorrectly) encode. */
    private static final int MAX_CASCADE_DEPTH = 50;

    private final TaMilestoneRepository taMilestoneRepository;
    private final TaTemplateMilestoneRepository taTemplateMilestoneRepository;
    private final TaTemplateService taTemplateService;
    private final OrderService orderService;
    private final AuditService auditService;

    /** Document A15: called by OrderService on order confirmation. */
    @Transactional
    public List<TaMilestoneResponse> instantiateForOrder(Long orderId, Long styleIdForTemplateResolution) {
        Order order = orderService.findInCurrentOrganization(orderId);
        if (order.getExFactoryDate() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Order must have an ex-factory date before T&A can be generated");
        }
        if (taMilestoneRepository.existsByOrderId(orderId)) {
            throw new ApiException(HttpStatus.CONFLICT, "T&A milestones already exist for this order");
        }

        TaTemplate template = taTemplateService.resolveForOrder(styleIdForTemplateResolution, order.getBuyer().getId());
        List<TaTemplateMilestone> templateMilestones = taTemplateMilestoneRepository.findByTemplateIdOrderBySequence(template.getId());

        Map<Long, TaMilestone> createdByTemplateMilestoneId = new HashMap<>();
        for (TaTemplateMilestone tm : templateMilestones) {
            TaMilestone milestone = new TaMilestone();
            milestone.setOrder(order);
            milestone.setMilestoneType(tm.getMilestoneType());
            milestone.setSequence(tm.getSequence());
            milestone.setPlannedDate(order.getExFactoryDate().minusDays(tm.getOffsetDaysFromExfactory()));
            milestone = taMilestoneRepository.save(milestone);
            createdByTemplateMilestoneId.put(tm.getId(), milestone);
        }
        // Second pass: wire dependencies now that every row has an id.
        for (TaTemplateMilestone tm : templateMilestones) {
            if (tm.getDependsOnMilestone() != null) {
                TaMilestone milestone = createdByTemplateMilestoneId.get(tm.getId());
                milestone.setDependsOnMilestone(createdByTemplateMilestoneId.get(tm.getDependsOnMilestone().getId()));
                taMilestoneRepository.save(milestone);
            }
        }

        auditService.record("TA_MILESTONES_GENERATED", "Order", orderId, null, templateMilestones.size(), "template=" + template.getId());
        return list(orderId);
    }

    /**
     * Document A16: recording a later-than-planned actual date cascades the delay
     * forward onto every milestone that (directly or transitively) depends on this
     * one, shifting their revised_date — never their locked planned_date or any
     * already-recorded actual_date — and recording an audit entry PER shifted
     * milestone so the cascade is never silent (Doc 13.1 risk mitigation).
     */
    @Transactional
    public TaMilestoneResponse recordActualDate(Long milestoneId, RecordActualDateRequest request) {
        TaMilestone milestone = findInCurrentOrganization(milestoneId);

        long delta = ChronoUnit.DAYS.between(milestone.getEffectiveDate(), request.actualDate());
        if (delta > 0 && (request.delayReason() == null || request.delayReason().isBlank())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "delayReason is required when the actual date is later than planned");
        }

        milestone.setActualDate(request.actualDate());
        if (delta > 0) {
            milestone.setDelayReason(request.delayReason());
        }
        milestone = taMilestoneRepository.save(milestone);

        if (delta > 0) {
            cascadeDelay(milestone, delta, 0);
        }

        auditService.record("TA_MILESTONE_ACTUAL_DATE", "TaMilestone", milestone.getId(), null, request.actualDate(), request.delayReason());
        return toResponse(milestone);
    }

    private void cascadeDelay(TaMilestone source, long deltaDays, int depth) {
        if (depth >= MAX_CASCADE_DEPTH) {
            return; // defensive stop — see MAX_CASCADE_DEPTH javadoc
        }
        List<TaMilestone> dependents = taMilestoneRepository.findByDependsOnMilestoneId(source.getId());
        for (TaMilestone dependent : dependents) {
            if (dependent.getActualDate() != null) {
                continue; // already completed — don't rewrite history (Doc 9.5)
            }
            LocalDate shifted = dependent.getEffectiveDate().plusDays(deltaDays);
            if (!shifted.isAfter(dependent.getEffectiveDate())) {
                continue; // only ever pushes dates later, never pulls them earlier
            }
            dependent.setRevisedDate(shifted);
            taMilestoneRepository.save(dependent);

            // Document 13.1 risk mitigation: an audit entry per shifted milestone, naming
            // the responsible user, so the cascade is traceable even before Phase 11+'s
            // real push-notification dispatch exists — "never silent" via the audit log.
            auditService.record("TA_MILESTONE_CASCADED_DELAY", "TaMilestone", dependent.getId(),
                    dependent.getPlannedDate(), shifted,
                    "cascaded from milestone " + source.getId()
                            + (dependent.getResponsibleUser() != null ? "; responsible user=" + dependent.getResponsibleUser().getId() : ""));

            cascadeDelay(dependent, deltaDays, depth + 1);
        }
    }

    @Transactional(readOnly = true)
    public List<TaMilestoneResponse> list(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return taMilestoneRepository.findByOrderIdOrderBySequence(orderId).stream().map(this::toResponse).toList();
    }

    public TaMilestone findInCurrentOrganization(Long milestoneId) {
        AuthenticatedUser user = (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return taMilestoneRepository.findByIdAndOrder_Organization_Id(milestoneId, user.organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "T&A milestone not found"));
    }

    /** Document 9.5: status derivation precedence — DONE > BLOCKED > CRITICAL_DELAY > OVERDUE > DUE_TODAY > UPCOMING > PENDING. */
    private TaMilestoneStatus computeStatus(TaMilestone milestone) {
        if (milestone.getActualDate() != null) {
            return TaMilestoneStatus.DONE;
        }
        LocalDate today = LocalDate.now();
        LocalDate effective = milestone.getEffectiveDate();

        if (milestone.getDependsOnMilestone() != null
                && milestone.getDependsOnMilestone().getActualDate() == null
                && !effective.isAfter(today)) {
            return TaMilestoneStatus.BLOCKED;
        }
        long daysOverdue = ChronoUnit.DAYS.between(effective, today);
        if (daysOverdue > CRITICAL_DELAY_THRESHOLD_DAYS) {
            return TaMilestoneStatus.CRITICAL_DELAY;
        }
        if (daysOverdue > 0) {
            return TaMilestoneStatus.OVERDUE;
        }
        if (daysOverdue == 0) {
            return TaMilestoneStatus.DUE_TODAY;
        }
        if (daysOverdue >= -3) {
            return TaMilestoneStatus.UPCOMING;
        }
        return TaMilestoneStatus.PENDING;
    }

    private TaMilestoneResponse toResponse(TaMilestone milestone) {
        TaMilestoneStatus status = computeStatus(milestone);
        long delayDays = milestone.getActualDate() != null
                ? ChronoUnit.DAYS.between(milestone.getPlannedDate(), milestone.getActualDate())
                : Math.max(0, ChronoUnit.DAYS.between(milestone.getEffectiveDate(), LocalDate.now()));
        return new TaMilestoneResponse(milestone.getId(), milestone.getOrder().getId(), milestone.getMilestoneType().getId(),
                milestone.getMilestoneType().getName(), milestone.getSequence(), milestone.getPlannedDate(),
                milestone.getRevisedDate(), milestone.getActualDate(),
                milestone.getResponsibleUser() != null ? milestone.getResponsibleUser().getId() : null,
                milestone.getResponsibleFactory() != null ? milestone.getResponsibleFactory().getId() : null,
                status, milestone.getDependsOnMilestone() != null ? milestone.getDependsOnMilestone().getId() : null,
                milestone.getDelayReason(), delayDays);
    }
}
