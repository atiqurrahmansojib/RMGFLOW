package com.rmgflow.order.dto;

import com.rmgflow.order.entity.OrderAmendmentStatus;

import java.time.Instant;

public record OrderAmendmentResponse(
        Long id, Long orderId, int amendmentNo, String fieldChanged, String oldValue, String newValue,
        String reason, Long requestedById, Long approvedById, OrderAmendmentStatus status, Instant createdAt
) {
}
