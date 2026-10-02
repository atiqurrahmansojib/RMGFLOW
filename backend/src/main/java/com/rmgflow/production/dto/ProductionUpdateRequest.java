package com.rmgflow.production.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record ProductionUpdateRequest(
        @NotNull LocalDate updateDate,
        @Min(0) int cuttingQty,
        @Min(0) int sewingQty,
        @Min(0) int finishingQty,
        @Min(0) int packingQty,
        @Min(0) int rejectionQty,
        @Min(0) int alterationQty
) {
}
