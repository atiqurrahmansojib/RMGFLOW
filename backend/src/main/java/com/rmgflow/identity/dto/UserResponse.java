package com.rmgflow.identity.dto;

import java.util.Set;

public record UserResponse(Long id, String email, String fullName, String phone, boolean active, Set<String> roleNames) {
}
