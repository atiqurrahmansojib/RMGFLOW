package com.rmgflow.inquiry.dto;

import com.rmgflow.inquiry.entity.InquiryStatus;
import jakarta.validation.constraints.NotNull;

/** Document 10.1: WON needs no reason; LOST always does (Doc 4.3 taxonomy, enforced at DB + service level). */
public record MarkWonLostRequest(@NotNull InquiryStatus status, String lostReason) {
}
