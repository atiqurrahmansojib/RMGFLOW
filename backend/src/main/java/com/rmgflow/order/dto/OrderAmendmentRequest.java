package com.rmgflow.order.dto;

import jakarta.validation.constraints.NotBlank;

public record OrderAmendmentRequest(
        @NotBlank String fieldChanged,
        String newValue,
        @NotBlank String reason
) {
}
