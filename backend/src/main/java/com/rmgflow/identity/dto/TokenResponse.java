package com.rmgflow.identity.dto;

public record TokenResponse(String accessToken, String refreshToken, long accessTokenExpiresInSeconds) {
}
