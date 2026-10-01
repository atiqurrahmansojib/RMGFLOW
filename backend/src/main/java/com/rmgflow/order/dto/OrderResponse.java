package com.rmgflow.order.dto;

import com.rmgflow.order.entity.OrderStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record OrderResponse(
        Long id, String orderNo, String buyerPoNo, Long buyerId, Long quotationId, OrderStatus status,
        LocalDate orderDate, LocalDate exFactoryDate, LocalDate deliveryDate, String incoterm,
        Long paymentTermsId, String destinationCountry, BigDecimal totalValue, String currency,
        int version, List<OrderItemResponse> items
) {
}
