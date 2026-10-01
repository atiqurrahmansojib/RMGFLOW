package com.rmgflow.quotation.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record QuotationRequest(
        @NotNull Long costingId,
        String quotationNo,
        @NotNull Long buyerId,
        @NotNull Long styleId,
        @NotNull @Positive Integer quantity,
        @NotNull @Positive BigDecimal unitPrice,
        @NotNull String currency,
        String incoterm,
        Long paymentTermsId,
        LocalDate validityDate,
        Integer leadTimeDays
) {
}
