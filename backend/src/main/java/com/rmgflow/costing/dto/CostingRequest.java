package com.rmgflow.costing.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.List;

public record CostingRequest(
        @NotNull Long styleId,
        Long inquiryId,
        @NotNull String currency,
        @NotNull @Positive BigDecimal exchangeRate,
        @NotNull @Positive Integer quantity,
        BigDecimal targetPrice,
        @NotEmpty @Valid List<CostingItemRequest> items
) {
}
