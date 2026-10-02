package com.rmgflow.financial.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ReceivableRequest(
        @NotNull Long buyerId, @NotNull @Positive BigDecimal amount, @NotNull String currency, @NotNull LocalDate dueDate
) {
}
