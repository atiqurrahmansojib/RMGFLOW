package com.rmgflow.sample.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record SampleRequest(
        @NotNull Long styleId,
        @NotNull Long buyerId,
        Long factoryId,
        @NotNull Long sampleTypeId,
        @NotNull LocalDate requestDate,
        LocalDate requiredDate
) {
}
