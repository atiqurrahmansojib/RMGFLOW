package com.rmgflow.factory.dto;

import com.rmgflow.factory.entity.PartnerType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record FactoryRequest(
        @NotBlank String code,
        @NotBlank String name,
        @NotNull PartnerType partnerType,
        String legalEntityName,
        String address,
        String country,
        Integer capacityPerMonth,
        Integer version
) {
}
