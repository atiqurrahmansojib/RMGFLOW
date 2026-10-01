package com.rmgflow.style.dto;

public record StyleResponse(
        Long id, String styleNo, Long buyerId, String buyerStyleNo, String productCategory,
        Long seasonId, String gender, String description, Long currentRevisionId, boolean active
) {
}
