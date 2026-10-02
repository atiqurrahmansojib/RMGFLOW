package com.rmgflow.financial.dto;

import java.math.BigDecimal;

/** Document 9.10: operationalMarginPercent is always computed server-side (never
 * client-supplied) — uses realizedUnitPrice if set, else falls back to quotedUnitPrice,
 * with isEstimate telling the caller which basis was used. */
public record OrderFinancialsResponse(
        Long id, Long orderId, BigDecimal quotedUnitPrice, BigDecimal actualCostUnit,
        BigDecimal realizedUnitPrice, BigDecimal operationalMarginPercent, boolean isEstimate
) {
}
