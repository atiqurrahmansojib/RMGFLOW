package com.rmgflow.shipment.dto;

import com.rmgflow.shipment.entity.ShipmentStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ShipmentResponse(
        Long id, String shipmentNo, Long orderId, LocalDate shipmentDate, LocalDate etd, LocalDate eta,
        int quantityShipped, Integer cartons, BigDecimal grossWeight, BigDecimal netWeight, BigDecimal volumeCbm,
        String portOfLoading, String portOfDischarge, Long forwarderId, String shippingLine, String containerNo,
        String blAwbNo, ShipmentStatus status, boolean partial, Long authorizedById
) {
}
