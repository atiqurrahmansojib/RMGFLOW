package com.rmgflow.production.dto;

import java.time.LocalDate;

public record ProductionUpdateResponse(
        Long id, Long orderId, LocalDate updateDate, int cuttingQty, int sewingQty, int finishingQty,
        int packingQty, int rejectionQty, int alterationQty
) {
}
