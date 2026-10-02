package com.rmgflow.financial.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ReceivableResponse(
        Long id, Long orderId, Long buyerId, BigDecimal amount, String currency, LocalDate dueDate,
        BigDecimal receivedAmount, String status
) {
}
