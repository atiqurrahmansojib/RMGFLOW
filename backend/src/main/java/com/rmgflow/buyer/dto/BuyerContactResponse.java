package com.rmgflow.buyer.dto;

public record BuyerContactResponse(
        Long id, Long buyerId, String name, String department, String email, String phone, boolean primary
) {
}
