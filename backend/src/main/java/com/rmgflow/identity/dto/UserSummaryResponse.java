package com.rmgflow.identity.dto;

import java.util.Set;

/** Minimal, non-sensitive user row for pickers (e.g. task assignee): no phone, no audit data. */
public record UserSummaryResponse(Long id, String fullName, String email, Set<String> roles, boolean active) {
}
