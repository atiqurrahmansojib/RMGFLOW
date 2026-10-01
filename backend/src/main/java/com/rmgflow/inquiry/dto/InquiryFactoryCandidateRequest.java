package com.rmgflow.inquiry.dto;

import jakarta.validation.constraints.NotNull;

public record InquiryFactoryCandidateRequest(@NotNull Long factoryId) {
}
