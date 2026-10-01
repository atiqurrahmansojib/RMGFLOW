package com.rmgflow.approval.dto;

import com.rmgflow.approval.entity.ApprovalStatus;
import jakarta.validation.constraints.NotNull;

public record ApprovalDecisionRequest(@NotNull ApprovalStatus decision, String comments, String rejectionReason) {
}
