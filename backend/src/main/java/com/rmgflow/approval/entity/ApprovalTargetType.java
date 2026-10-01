package com.rmgflow.approval.entity;

/** Document 8.4/ADR-08: every gate the shared approval engine covers. */
public enum ApprovalTargetType {
    COSTING, QUOTATION, SAMPLE_REVISION, LAB_DIP, TRIM, PP_SAMPLE, INSPECTION, SHIPMENT, DOCUMENT
}
