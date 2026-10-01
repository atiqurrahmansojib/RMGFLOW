package com.rmgflow.ta.dto;

import jakarta.validation.constraints.NotBlank;

public record TaTemplateRequest(@NotBlank String name, Long buyerId, Long styleId, boolean isDefault) {
}
