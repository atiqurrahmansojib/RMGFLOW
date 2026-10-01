package com.rmgflow.approval.service;

import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.Approval;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;
import com.rmgflow.approval.repository.ApprovalRepository;
import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Document 6.3/8.4/ADR-08: the ONE approval engine every gated module (costing,
 * quotation, sampling, quality, shipment, documents) calls — implement the state
 * machine once here, not six times. A rejected/returned round is never mutated
 * into "approved" later (Doc 9.3 invariant): the caller submits a NEW round via
 * submit() again, this service never offers a way to re-decide an existing one
 * (the DB trigger in V12 backs this up even against a bug).
 */
@Service
@RequiredArgsConstructor
public class ApprovalService {

    private static final Set<ApprovalStatus> DECIDABLE_FROM = EnumSet.of(ApprovalStatus.SUBMITTED, ApprovalStatus.PENDING);
    private static final Set<ApprovalStatus> VALID_DECISIONS = EnumSet.of(
            ApprovalStatus.APPROVED, ApprovalStatus.REJECTED, ApprovalStatus.RETURNED, ApprovalStatus.WITHDRAWN);

    /**
     * Security: decide() is reachable from one generic controller regardless of
     * target type (Doc 7 #68), so the permission check has to live HERE, mapped by
     * target type, rather than relying on a per-module @PreAuthorize that this
     * shared endpoint never goes through. Deliberately fail-closed: a target type
     * with no entry here (sample/quality/shipment/document approvals land in later
     * phases) is decidable by SUPER_ADMIN only until its module registers a real
     * permission — never silently open to any authenticated user.
     */
    private static final Map<ApprovalTargetType, String> DECISION_PERMISSION_BY_TARGET_TYPE = new EnumMap<>(ApprovalTargetType.class);
    static {
        DECISION_PERMISSION_BY_TARGET_TYPE.put(ApprovalTargetType.COSTING, "COSTING_APPROVE");
        DECISION_PERMISSION_BY_TARGET_TYPE.put(ApprovalTargetType.QUOTATION, "QUOTATION_APPROVE");
        DECISION_PERMISSION_BY_TARGET_TYPE.put(ApprovalTargetType.SAMPLE_REVISION, "SAMPLE_APPROVE");
    }

    private final ApprovalRepository approvalRepository;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public ApprovalResponse submit(ApprovalTargetType targetType, Long targetId) {
        int nextRound = approvalRepository.findTopByTargetTypeAndTargetIdOrderByRoundNoDesc(targetType, targetId)
                .map(a -> a.getRoundNo() + 1)
                .orElse(1);

        Approval approval = new Approval();
        approval.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        approval.setTargetType(targetType);
        approval.setTargetId(targetId);
        approval.setRoundNo(nextRound);
        approval.setStatus(ApprovalStatus.SUBMITTED);
        approval.setSubmittedBy(userRepository.getReferenceById(currentUser().id()));
        approval = approvalRepository.save(approval);

        auditService.record("APPROVAL_SUBMIT", targetType.name(), targetId, null, toResponse(approval), null);
        return toResponse(approval);
    }

    @Transactional
    public ApprovalResponse decide(Long approvalId, ApprovalDecisionRequest request) {
        Approval approval = findInCurrentOrganization(approvalId);
        requireDecisionPermission(approval.getTargetType());

        if (!DECIDABLE_FROM.contains(approval.getStatus())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Cannot decide an approval round that is already " + approval.getStatus());
        }
        if (!VALID_DECISIONS.contains(request.decision())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid decision: " + request.decision());
        }
        if (request.decision() == ApprovalStatus.REJECTED
                && (request.rejectionReason() == null || request.rejectionReason().isBlank())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "rejectionReason is required when rejecting");
        }

        ApprovalStatus before = approval.getStatus();
        approval.setStatus(request.decision());
        approval.setComments(request.comments());
        approval.setRejectionReason(request.decision() == ApprovalStatus.REJECTED ? request.rejectionReason() : null);
        approval.setDecidedBy(userRepository.getReferenceById(currentUser().id()));
        approval.setDecidedAt(Instant.now());
        approval = approvalRepository.save(approval);

        auditService.record("APPROVAL_DECIDE", approval.getTargetType().name(), approval.getTargetId(), before, approval.getStatus(), request.rejectionReason());
        return toResponse(approval);
    }

    @Transactional(readOnly = true)
    public List<ApprovalResponse> history(ApprovalTargetType targetType, Long targetId) {
        return approvalRepository.findByTargetTypeAndTargetIdOrderByRoundNoDesc(targetType, targetId)
                .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public ApprovalResponse latest(ApprovalTargetType targetType, Long targetId) {
        return approvalRepository.findTopByTargetTypeAndTargetIdOrderByRoundNoDesc(targetType, targetId)
                .map(this::toResponse)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No approval round found"));
    }

    @Transactional(readOnly = true)
    public Page<ApprovalResponse> pendingInbox(ApprovalTargetType targetType, Pageable pageable) {
        Long organizationId = currentUser().organizationId();
        Page<Approval> page = targetType != null
                ? approvalRepository.findByOrganizationIdAndTargetType(organizationId, targetType, pageable)
                : approvalRepository.findByOrganizationIdAndStatus(organizationId, ApprovalStatus.SUBMITTED, pageable);
        return page.map(this::toResponse);
    }

    private void requireDecisionPermission(ApprovalTargetType targetType) {
        String requiredPermission = DECISION_PERMISSION_BY_TARGET_TYPE.get(targetType);
        boolean isSuperAdmin = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (isSuperAdmin) return;

        if (requiredPermission == null) {
            throw new AccessDeniedException("Approvals for " + targetType + " are not yet supported for non-admin roles");
        }
        boolean hasPermission = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals(requiredPermission));
        if (!hasPermission) {
            throw new AccessDeniedException("Missing permission " + requiredPermission + " to decide this approval");
        }
    }

    private Approval findInCurrentOrganization(Long approvalId) {
        return approvalRepository.findByIdAndOrganizationId(approvalId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Approval not found"));
    }

    private ApprovalResponse toResponse(Approval approval) {
        return new ApprovalResponse(
                approval.getId(), approval.getTargetType(), approval.getTargetId(), approval.getRoundNo(), approval.getStatus(),
                approval.getSubmittedBy() != null ? approval.getSubmittedBy().getId() : null, approval.getSubmittedAt(),
                approval.getDecidedBy() != null ? approval.getDecidedBy().getId() : null, approval.getDecidedAt(),
                approval.getComments(), approval.getRejectionReason());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
