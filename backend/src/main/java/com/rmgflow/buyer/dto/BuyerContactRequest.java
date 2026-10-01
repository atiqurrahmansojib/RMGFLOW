package com.rmgflow.buyer.dto;

import jakarta.validation.constraints.NotBlank;

public record BuyerContactRequest(
        @NotBlank String name,
        String department,
        String email,
        String phone,
        boolean primary
) {
}
