package com.rmgflow.approval.dto;

import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;

import java.time.Instant;

public record ApprovalResponse(
        Long id, ApprovalTargetType targetType, Long targetId, int roundNo, ApprovalStatus status,
        Long submittedById, Instant submittedAt, Long decidedById, Instant decidedAt,
        String comments, String rejectionReason
) {
}
