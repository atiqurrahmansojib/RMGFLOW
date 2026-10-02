package com.rmgflow.financial.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PaymentRecordResponse(
        Long id, Long receivableId, Long payableId, BigDecimal amount, LocalDate paidDate, String method, String referenceNo
) {
}
