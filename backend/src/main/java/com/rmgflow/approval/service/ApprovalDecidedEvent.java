package com.rmgflow.approval.service;

import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;

/**
 * Published synchronously (inside decide()'s transaction) after an approval round is
 * decided, so the owning module can roll the decision onto its own record — e.g. a
 * costing flips DRAFT -> APPROVED — without the approval engine depending on every
 * module (Doc 10.2/10.5). A listener failure rolls the decision back with it.
 */
public record ApprovalDecidedEvent(ApprovalTargetType targetType, Long targetId, ApprovalStatus decision) {
}
