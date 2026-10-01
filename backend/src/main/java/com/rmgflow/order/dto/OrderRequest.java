package com.rmgflow.order.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.List;

public record OrderRequest(
        @NotBlank String buyerPoNo,
        @NotNull Long buyerId,
        Long quotationId,
        @NotNull LocalDate orderDate,
        LocalDate exFactoryDate,
        LocalDate deliveryDate,
        String incoterm,
        Long paymentTermsId,
        String destinationCountry,
        @NotNull String currency,
        boolean overrideFactoryApproval,
        String overrideReason,
        @NotEmpty @Valid List<OrderItemRequest> items
) {
}
