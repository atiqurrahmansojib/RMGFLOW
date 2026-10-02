package com.rmgflow.financial.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PaymentRecordRequest(
        Long receivableId, Long payableId, @NotNull @Positive BigDecimal amount,
        @NotNull LocalDate paidDate, String method, String referenceNo
) {
}
