package com.rmgflow.factory.dto;

import jakarta.validation.constraints.NotBlank;

public record FactoryCapabilityRequest(@NotBlank String productCategory) {
}
