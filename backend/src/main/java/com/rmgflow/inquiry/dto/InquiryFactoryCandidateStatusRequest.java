package com.rmgflow.inquiry.dto;

import com.rmgflow.inquiry.entity.InquiryFactoryCandidateStatus;
import jakarta.validation.constraints.NotNull;

public record InquiryFactoryCandidateStatusRequest(@NotNull InquiryFactoryCandidateStatus status) {
}
