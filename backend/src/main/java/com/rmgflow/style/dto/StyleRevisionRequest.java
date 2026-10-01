package com.rmgflow.style.dto;

import java.math.BigDecimal;

public record StyleRevisionRequest(
        String fabric, String composition, BigDecimal gsm, String color, String sizeRange, String measurementSpecJson
) {
}
