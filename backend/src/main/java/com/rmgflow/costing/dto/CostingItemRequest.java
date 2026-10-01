package com.rmgflow.costing.dto;

import com.rmgflow.costing.entity.CostingComponentType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CostingItemRequest(
        @NotNull CostingComponentType componentType,
        String description,
        @NotNull @PositiveOrZero BigDecimal unitCost,
        @NotNull @PositiveOrZero BigDecimal consumption,
        @NotNull @PositiveOrZero BigDecimal wastagePercent
) {
}
