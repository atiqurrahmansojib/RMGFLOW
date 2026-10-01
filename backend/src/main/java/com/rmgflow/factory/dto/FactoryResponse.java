package com.rmgflow.factory.dto;

import com.rmgflow.factory.entity.PartnerType;

public record FactoryResponse(
        Long id,
        String code,
        String name,
        PartnerType partnerType,
        String legalEntityName,
        String address,
        String country,
        Integer capacityPerMonth,
        boolean active,
        int version
) {
}
