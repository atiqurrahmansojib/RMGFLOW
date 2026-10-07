package com.rmgflow.ta.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.masterdata.repository.MilestoneTypeRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.style.service.StyleService;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.ta.dto.TaTemplateMilestoneRequest;
import com.rmgflow.ta.dto.TaTemplateMilestoneResponse;
import com.rmgflow.ta.dto.TaTemplateRequest;
import com.rmgflow.ta.dto.TaTemplateResponse;
import com.rmgflow.ta.entity.TaTemplate;
import com.rmgflow.ta.entity.TaTemplateMilestone;
import com.rmgflow.ta.repository.TaTemplateMilestoneRepository;
import com.rmgflow.ta.repository.TaTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 8.7/FR-80: configurable milestone templates — no hardcoded fixed list. */
@Service
@RequiredArgsConstructor
public class TaTemplateService {

    private final TaTemplateRepository taTemplateRepository;
    private final TaTemplateMilestoneRepository taTemplateMilestoneRepository;
    private final BuyerService buyerService;
    private final StyleService styleService;
    private final MilestoneTypeRepository milestoneTypeRepository;
    private final OrganizationRepository organizationRepository;

    @Transactional
    public TaTemplateResponse create(TaTemplateRequest request) {
        TaTemplate template = new TaTemplate();
        template.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        template.setName(request.name());
        template.setBuyer(request.buyerId() != null ? buyerService.findInCurrentOrganization(request.buyerId()) : null);
        template.setStyle(request.styleId() != null ? styleService.findInCurrentOrganization(request.styleId()) : null);
        template.setDefault(request.isDefault());
        template = taTemplateRepository.save(template);
        return toResponse(template);
    }

    @Transactional
    public TaTemplateMilestoneResponse addMilestone(Long templateId, TaTemplateMilestoneRequest request) {
        TaTemplate template = findInCurrentOrganization(templateId);
        if (!milestoneTypeRepository.existsById(request.milestoneTypeId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Milestone type not found");
        }

        TaTemplateMilestone milestone = new TaTemplateMilestone();
        milestone.setTemplate(template);
        milestone.setMilestoneType(milestoneTypeRepository.getReferenceById(request.milestoneTypeId()));
        milestone.setSequence(request.sequence());
        milestone.setOffsetDaysFromExfactory(request.offsetDaysFromExfactory());
        if (request.dependsOnMilestoneId() != null) {
            milestone.setDependsOnMilestone(taTemplateMilestoneRepository.getReferenceById(request.dependsOnMilestoneId()));
        }
        milestone = taTemplateMilestoneRepository.save(milestone);
        return toMilestoneResponse(milestone);
    }

    @Transactional(readOnly = true)
    public List<TaTemplateResponse> list() {
        return taTemplateRepository.findByOrganizationId(currentUser().organizationId()).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<TaTemplateMilestoneResponse> listMilestones(Long templateId) {
        findInCurrentOrganization(templateId);
        return taTemplateMilestoneRepository.findByTemplateIdOrderBySequence(templateId).stream().map(this::toMilestoneResponse).toList();
    }

    public TaTemplate findInCurrentOrganization(Long templateId) {
        return taTemplateRepository.findByIdAndOrganizationId(templateId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "T&A template not found"));
    }

    /** Document 10.3: style-specific wins over buyer-specific wins over org default. */
    @Transactional(readOnly = true)
    public TaTemplate resolveForOrder(Long styleId, Long buyerId) {
        return findForOrder(styleId, buyerId)
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST,
                        "No T&A template resolves for this order (no style-specific, buyer-specific, or default template exists)"));
    }

    /** Same resolution as {@link #resolveForOrder} but never throws (used by A15 auto-generation). */
    public java.util.Optional<TaTemplate> findForOrder(Long styleId, Long buyerId) {
        Long organizationId = currentUser().organizationId();
        return (styleId != null ? taTemplateRepository.findFirstByOrganizationIdAndStyleId(organizationId, styleId)
                        : java.util.Optional.<TaTemplate>empty())
                .or(() -> taTemplateRepository.findFirstByOrganizationIdAndBuyerIdAndStyleIsNull(organizationId, buyerId))
                .or(() -> taTemplateRepository.findFirstByOrganizationIdAndIsDefaultTrue(organizationId));
    }

    private TaTemplateResponse toResponse(TaTemplate template) {
        return new TaTemplateResponse(template.getId(), template.getName(),
                template.getBuyer() != null ? template.getBuyer().getId() : null,
                template.getStyle() != null ? template.getStyle().getId() : null, template.isDefault());
    }

    private TaTemplateMilestoneResponse toMilestoneResponse(TaTemplateMilestone milestone) {
        return new TaTemplateMilestoneResponse(milestone.getId(), milestone.getTemplate().getId(),
                milestone.getMilestoneType().getId(), milestone.getSequence(), milestone.getOffsetDaysFromExfactory(),
                milestone.getDependsOnMilestone() != null ? milestone.getDependsOnMilestone().getId() : null);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
