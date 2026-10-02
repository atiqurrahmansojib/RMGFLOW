package com.rmgflow.quality.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record DefectRequest(
        @NotNull Long defectTypeId,
        @Positive int quantity,
        @NotBlank String severity,
        Long photoDocumentId
) {
}
