package com.rmgflow.inquiry.dto;

import com.rmgflow.inquiry.entity.InquiryStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public record InquiryResponse(
        Long id,
        String inquiryNo,
        Long buyerId,
        String buyerName,
        Long seasonId,
        Long merchandiserId,
        Integer targetQuantity,
        BigDecimal targetPrice,
        String targetCurrency,
        LocalDate deliveryRequirement,
        InquiryStatus status,
        String lostReason
) {
}
