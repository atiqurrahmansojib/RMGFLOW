package com.rmgflow.approval.entity;

/** Document 8.4/FR-111: the full round lifecycle — history is append-only (new round, not edit). */
public enum ApprovalStatus {
    SUBMITTED, PENDING, APPROVED, REJECTED, RETURNED, RESUBMITTED, WITHDRAWN
}
