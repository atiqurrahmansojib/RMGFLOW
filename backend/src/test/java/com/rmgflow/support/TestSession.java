package com.rmgflow.support;

/** Bundles what a test usually needs after creating/logging in a test user:
 * the bearer token to call the API with, and the organization id it landed in
 * (needed when a second user must be created in the SAME tenant). */
public record TestSession(String accessToken, Long organizationId) {
}
