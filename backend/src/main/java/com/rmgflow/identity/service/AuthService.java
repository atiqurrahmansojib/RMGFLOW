package com.rmgflow.identity.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.identity.dto.LoginRequest;
import com.rmgflow.identity.dto.TokenResponse;
import com.rmgflow.identity.entity.Session;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.SessionRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Document 15.1/ADR-04: login issues a short-lived access token + a rotating refresh
 * token. Each refresh invalidates the prior token (theft/replay of a revoked token
 * is detectable since it will no longer match an active session).
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final SessionRepository sessionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public TokenResponse login(LoginRequest request, String ipAddress) {
        User user = userRepository.findByEmailIgnoreCase(request.email())
                .filter(User::isActive)
                .orElseThrow(() -> new org.springframework.security.authentication.BadCredentialsException("Invalid credentials"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Invalid credentials");
        }

        return issueTokens(user, request.deviceInfo(), ipAddress);
    }

    @Transactional
    public TokenResponse refresh(String refreshToken, String deviceInfo, String ipAddress) {
        String hash = hash(refreshToken);
        Session session = sessionRepository.findByRefreshTokenHash(hash)
                .filter(Session::isActive)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Refresh token invalid or expired"));

        session.setRevokedAt(Instant.now());
        sessionRepository.save(session);

        return issueTokens(session.getUser(), deviceInfo, ipAddress);
    }

    @Transactional
    public void logout(String refreshToken) {
        String hash = hash(refreshToken);
        sessionRepository.findByRefreshTokenHash(hash).ifPresent(session -> {
            session.setRevokedAt(Instant.now());
            sessionRepository.save(session);
        });
    }

    private TokenResponse issueTokens(User user, String deviceInfo, String ipAddress) {
        Set<String> roleNames = user.getRoles().stream().map(r -> r.getName()).collect(Collectors.toUnmodifiableSet());
        AuthenticatedUser principal = new AuthenticatedUser(user.getId(), user.getOrganization().getId(), user.getEmail(), roleNames);

        String accessToken = jwtService.generateAccessToken(principal);
        String rawRefreshToken = generateRawToken();

        Session session = new Session();
        session.setUser(user);
        session.setRefreshTokenHash(hash(rawRefreshToken));
        session.setDeviceInfo(deviceInfo);
        session.setIpAddress(ipAddress);
        session.setExpiresAt(Instant.now().plus(jwtService.refreshTokenTtlDays(), ChronoUnit.DAYS));
        sessionRepository.save(session);

        return new TokenResponse(accessToken, rawRefreshToken, 15L * 60);
    }

    private String generateRawToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hashed);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
