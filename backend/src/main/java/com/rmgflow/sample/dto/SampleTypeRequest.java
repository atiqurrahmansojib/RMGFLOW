package com.rmgflow.sample.dto;

import jakarta.validation.constraints.NotBlank;

/** buyerId set = a buyer-specific sample type (Doc 9 §9); omitted = a standard type. */
public record SampleTypeRequest(@NotBlank String name, Long buyerId) {
}
