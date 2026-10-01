package com.rmgflow.buyer.dto;

public record BuyerResponse(
        Long id,
        String code,
        String name,
        String groupName,
        String country,
        String defaultCurrency,
        Long defaultPaymentTermsId,
        String defaultIncoterm,
        boolean active,
        int version
) {
}
