package com.rmgflow.quality.dto;

import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;

public record InspectionRequest(
        @NotNull InspectionType inspectionType,
        @NotNull LocalDate inspectionDate,
        @Positive int inspectedQty,
        String aqlLevel,
        @NotNull InspectionResult result
) {
}
