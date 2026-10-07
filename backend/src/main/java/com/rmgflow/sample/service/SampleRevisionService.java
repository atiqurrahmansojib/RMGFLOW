package com.rmgflow.sample.service;

import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;
import com.rmgflow.approval.service.ApprovalDecidedEvent;
import com.rmgflow.approval.service.ApprovalService;
import com.rmgflow.audit.service.AuditService;
import com.rmgflow.sample.dto.SampleRevisionRequest;
import com.rmgflow.sample.dto.SampleRevisionResponse;
import com.rmgflow.sample.entity.Sample;
import com.rmgflow.sample.entity.SampleRevision;
import com.rmgflow.sample.entity.SampleStatus;
import com.rmgflow.sample.repository.SampleRevisionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Document 9.3/FR-41/42/10.5: this is the module that makes Doc 9.3's invariant
 * literal — "a rejected sample revision never becomes approved via editing."
 * Rejection always means: call create() again for a NEW revision + a NEW
 * approval round (via the shared ApprovalService, its second real consumer
 * after costing — Doc 6.3/Phase 5 rationale). Nothing here ever updates a
 * prior revision row.
 */
@Service
@RequiredArgsConstructor
public class SampleRevisionService {

    private static final Map<ApprovalStatus, SampleStatus> SAMPLE_STATUS_BY_DECISION = Map.of(
            ApprovalStatus.APPROVED, SampleStatus.APPROVED,
            ApprovalStatus.REJECTED, SampleStatus.REJECTED,
            ApprovalStatus.RETURNED, SampleStatus.RETURNED
    );

    private final SampleRevisionRepository sampleRevisionRepository;
    private final SampleService sampleService;
    private final ApprovalService approvalService;
    private final AuditService auditService;

    @Transactional
    public SampleRevisionResponse create(Long sampleId, SampleRevisionRequest request) {
        Sample sample = sampleService.findInCurrentOrganization(sampleId);

        int nextRevisionNo = sampleRevisionRepository.findTopBySampleIdOrderByRevisionNoDesc(sampleId)
                .map(r -> r.getRevisionNo() + 1)
                .orElse(1);

        SampleRevision revision = new SampleRevision();
        revision.setSample(sample);
        revision.setRevisionNo(nextRevisionNo);
        revision.setSubmittedDate(request.submittedDate());
        revision.setComments(request.comments());
        revision = sampleRevisionRepository.save(revision);

        // Document 10.5: each new revision gets its own fresh approval round.
        approvalService.submit(ApprovalTargetType.SAMPLE_REVISION, revision.getId());
        sampleService.updateStatus(sampleId, SampleStatus.SUBMITTED);

        auditService.record("SAMPLE_REVISION_CREATE", "SampleRevision", revision.getId(), null, toResponse(revision), null);
        return toResponse(revision);
    }

    /**
     * Document 10.5: called after the revision's approval round is decided (via the
     * shared POST /api/v1/approvals/{id}/decide) — rolls the decision up onto the
     * parent sample's current_status. Deliberately re-reads the approval's actual
     * decided status from the approval engine rather than trusting a client-supplied
     * value, so this can't be used to set a sample to APPROVED without a real
     * decided approval existing.
     */
    @Transactional
    public SampleRevisionResponse syncStatusFromLatestApproval(Long sampleId) {
        Sample sample = sampleService.findInCurrentOrganization(sampleId);
        SampleRevision latestRevision = sampleRevisionRepository.findTopBySampleIdOrderByRevisionNoDesc(sampleId)
                .orElseThrow(() -> new com.rmgflow.common.ApiException(org.springframework.http.HttpStatus.NOT_FOUND, "No revision found for this sample"));

        ApprovalResponse latestApproval = approvalService.latest(ApprovalTargetType.SAMPLE_REVISION, latestRevision.getId());
        SampleStatus mapped = SAMPLE_STATUS_BY_DECISION.get(latestApproval.status());
        if (mapped == null) {
            throw new com.rmgflow.common.ApiException(org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Latest approval round is not yet decided (status=" + latestApproval.status() + ")");
        }
        sampleService.updateStatus(sample.getId(), mapped);
        return toResponse(latestRevision);
    }

    /** Rolls a decided revision round onto the sample automatically, so the status is
     * right without the client having to call sync-status afterwards. */
    @EventListener
    public void onApprovalDecided(ApprovalDecidedEvent event) {
        if (event.targetType() != ApprovalTargetType.SAMPLE_REVISION || !SAMPLE_STATUS_BY_DECISION.containsKey(event.decision())) {
            return;
        }
        sampleRevisionRepository.findById(event.targetId())
                .ifPresent(revision -> syncStatusFromLatestApproval(revision.getSample().getId()));
    }

    @Transactional(readOnly = true)
    public List<SampleRevisionResponse> list(Long sampleId) {
        sampleService.findInCurrentOrganization(sampleId);
        return sampleRevisionRepository.findBySampleIdOrderByRevisionNoDesc(sampleId).stream().map(this::toResponse).toList();
    }

    private SampleRevisionResponse toResponse(SampleRevision revision) {
        return new SampleRevisionResponse(revision.getId(), revision.getSample().getId(), revision.getRevisionNo(),
                revision.getSubmittedDate(), revision.getComments(), revision.getCreatedAt());
    }
}
