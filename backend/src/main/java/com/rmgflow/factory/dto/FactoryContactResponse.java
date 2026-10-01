package com.rmgflow.factory.dto;

public record FactoryContactResponse(
        Long id, Long factoryId, String name, String role, String email, String phone, boolean primary
) {
}
