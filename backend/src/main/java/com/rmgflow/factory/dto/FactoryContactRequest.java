package com.rmgflow.factory.dto;

import jakarta.validation.constraints.NotBlank;

public record FactoryContactRequest(
        @NotBlank String name, String role, String email, String phone, boolean primary
) {
}
