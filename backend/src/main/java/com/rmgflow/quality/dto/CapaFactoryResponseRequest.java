package com.rmgflow.quality.dto;

import jakarta.validation.constraints.NotBlank;

public record CapaFactoryResponseRequest(@NotBlank String factoryResponse) {
}
