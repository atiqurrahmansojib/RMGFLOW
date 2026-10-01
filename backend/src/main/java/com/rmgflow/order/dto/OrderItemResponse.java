package com.rmgflow.order.dto;

import java.math.BigDecimal;

public record OrderItemResponse(
        Long id, Long styleId, Long factoryId, String color, String size, int quantity, BigDecimal unitPrice
) {
}
