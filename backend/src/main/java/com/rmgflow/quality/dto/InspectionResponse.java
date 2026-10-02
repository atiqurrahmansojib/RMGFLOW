package com.rmgflow.quality.dto;

import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;

import java.time.LocalDate;

public record InspectionResponse(
        Long id, Long orderId, InspectionType inspectionType, LocalDate inspectionDate,
        int inspectedQty, String aqlLevel, InspectionResult result, Long inspectorId
) {
}
