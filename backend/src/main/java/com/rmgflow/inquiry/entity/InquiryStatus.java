package com.rmgflow.inquiry.entity;

/** Document 10.1: OPEN -> QUOTED -> WON/LOST, with HOLD as a pause from either OPEN or QUOTED. */
public enum InquiryStatus {
    OPEN, QUOTED, WON, LOST, HOLD
}
