package com.rmgflow.order.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

public record OrderItemRequest(
        @NotNull Long styleId,
        @NotNull Long factoryId,
        String color,
        String size,
        @NotNull @Positive Integer quantity,
        @NotNull @Positive BigDecimal unitPrice
) {
}
