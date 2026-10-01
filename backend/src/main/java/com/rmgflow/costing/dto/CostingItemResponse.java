package com.rmgflow.costing.dto;

import com.rmgflow.costing.entity.CostingComponentType;

import java.math.BigDecimal;

public record CostingItemResponse(
        Long id, CostingComponentType componentType, String description,
        BigDecimal unitCost, BigDecimal consumption, BigDecimal wastagePercent, BigDecimal totalCost
) {
}
