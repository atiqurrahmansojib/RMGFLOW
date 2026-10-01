package com.rmgflow.costing.dto;

import com.rmgflow.costing.entity.CostingStatus;

import java.math.BigDecimal;
import java.util.List;

public record CostingResponse(
        Long id, Long styleId, Long inquiryId, int versionNo, String currency, BigDecimal exchangeRate,
        int quantity, CostingStatus status, BigDecimal targetPrice, BigDecimal totalCost,
        BigDecimal marginPercent, Long supersededFromId, int version, List<CostingItemResponse> items
) {
}
