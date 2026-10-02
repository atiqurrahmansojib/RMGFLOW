package com.rmgflow.quality.dto;

import jakarta.validation.constraints.NotBlank;

public record CapaRecordRequest(
        Long defectId,
        Long inspectionId,
        @NotBlank String description,
        String correctiveAction,
        String preventiveAction
) {
}
