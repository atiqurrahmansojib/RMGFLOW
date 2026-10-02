package com.rmgflow.financial.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PayableResponse(
        Long id, Long orderId, Long factoryId, BigDecimal amount, String currency, LocalDate dueDate,
        BigDecimal paidAmount, String status
) {
}
