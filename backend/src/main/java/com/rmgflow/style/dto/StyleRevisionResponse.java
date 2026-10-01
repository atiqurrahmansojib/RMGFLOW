package com.rmgflow.style.dto;

import java.math.BigDecimal;
import java.time.Instant;

public record StyleRevisionResponse(
        Long id, Long styleId, int revisionNo, String fabric, String composition, BigDecimal gsm,
        String color, String sizeRange, String measurementSpecJson, Instant createdAt
) {
}
