package com.rmgflow.financial.dto;

import java.math.BigDecimal;

public record OrderFinancialsRequest(BigDecimal quotedUnitPrice, BigDecimal actualCostUnit, BigDecimal realizedUnitPrice) {
}
