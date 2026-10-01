package com.rmgflow.inquiry.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record InquiryRequest(
        @NotBlank String inquiryNo,
        @NotNull Long buyerId,
        Long seasonId,
        Long merchandiserId,
        Integer targetQuantity,
        BigDecimal targetPrice,
        String targetCurrency,
        LocalDate deliveryRequirement
) {
}
