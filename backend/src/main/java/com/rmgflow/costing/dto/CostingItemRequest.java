package com.rmgflow.costing.dto;

import com.rmgflow.costing.entity.CostingComponentType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CostingItemRequest(
        @NotNull CostingComponentType componentType,
        String description,
        /** Null = "keep the previous version's unit cost" (Doc 5.2: roles without
         * COSTING_VIEW_MARGIN never see unit costs, so they can't re-enter them). */
        @PositiveOrZero BigDecimal unitCost,
        @NotNull @PositiveOrZero BigDecimal consumption,
        @NotNull @PositiveOrZero BigDecimal wastagePercent,
        /** Line of the source costing this row continues; used to carry over a hidden unit cost. */
        Long sourceItemId
) {
    public CostingItemRequest(CostingComponentType componentType, String description, BigDecimal unitCost,
                              BigDecimal consumption, BigDecimal wastagePercent) {
        this(componentType, description, unitCost, consumption, wastagePercent, null);
    }
}
