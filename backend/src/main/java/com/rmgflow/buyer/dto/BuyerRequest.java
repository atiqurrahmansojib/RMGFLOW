package com.rmgflow.buyer.dto;

import jakarta.validation.constraints.NotBlank;

public record BuyerRequest(
        @NotBlank String code,
        @NotBlank String name,
        String groupName,
        String country,
        String defaultCurrency,
        Long defaultPaymentTermsId,
        String defaultIncoterm,
        Integer version
) {
}
