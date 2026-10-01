package com.rmgflow.quotation.dto;

import com.rmgflow.quotation.entity.QuotationStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public record QuotationResponse(
        Long id, Long costingId, String quotationNo, int versionNo, Long buyerId, Long styleId,
        int quantity, BigDecimal unitPrice, String currency, String incoterm, Long paymentTermsId,
        LocalDate validityDate, Integer leadTimeDays, QuotationStatus status, Long supersedesQuotationId, int version
) {
}
