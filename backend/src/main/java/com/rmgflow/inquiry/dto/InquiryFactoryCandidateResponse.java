package com.rmgflow.inquiry.dto;

import com.rmgflow.inquiry.entity.InquiryFactoryCandidateStatus;

public record InquiryFactoryCandidateResponse(Long id, Long inquiryId, Long factoryId, String factoryName, InquiryFactoryCandidateStatus status) {
}
