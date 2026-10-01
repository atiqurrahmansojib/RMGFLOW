package com.rmgflow.security;

import java.util.Set;

/** JWT principal: identity + role claims only, per Doc 15.1 (no sensitive data in the token). */
public record AuthenticatedUser(Long id, Long organizationId, String email, Set<String> roles) {
}
