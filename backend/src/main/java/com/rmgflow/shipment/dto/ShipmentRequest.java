package com.rmgflow.shipment.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ShipmentRequest(
        LocalDate shipmentDate,
        LocalDate etd,
        LocalDate eta,
        @NotNull @Positive Integer quantityShipped,
        Integer cartons,
        BigDecimal grossWeight,
        BigDecimal netWeight,
        BigDecimal volumeCbm,
        String portOfLoading,
        String portOfDischarge,
        Long forwarderId,
        String shippingLine,
        String containerNo,
        String blAwbNo,
        boolean overrideQualityGate,
        String overrideReason
) {
}
