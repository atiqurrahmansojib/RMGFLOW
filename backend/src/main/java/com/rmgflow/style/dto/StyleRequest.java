package com.rmgflow.style.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record StyleRequest(
        @NotBlank String styleNo,
        @NotNull Long buyerId,
        String buyerStyleNo,
        String productCategory,
        Long seasonId,
        String gender,
        String description
) {
}
