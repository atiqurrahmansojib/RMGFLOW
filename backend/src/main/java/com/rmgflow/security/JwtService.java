package com.rmgflow.security;

import com.rmgflow.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Document 15.1 / ADR-04: short-lived signed access tokens. Only identity + role
 * claims are embedded (no sensitive business data) so a decoded-but-unverified
 * token leaks nothing beyond "who" and "which roles."
 */
@Service
@RequiredArgsConstructor
public class JwtService {

    private final JwtProperties jwtProperties;

    private SecretKey key() {
        return Keys.hmacShaKeyFor(jwtProperties.secret().getBytes(StandardCharsets.UTF_8));
    }

    public String generateAccessToken(AuthenticatedUser user) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(user.id().toString())
                .claim("org", user.organizationId())
                .claim("email", user.email())
                .claim("roles", user.roles())
                .issuedAt(java.util.Date.from(now))
                .expiration(java.util.Date.from(now.plus(jwtProperties.accessTokenTtlMinutes(), ChronoUnit.MINUTES)))
                .signWith(key())
                .compact();
    }

    public AuthenticatedUser parseAccessToken(String token) {
        Claims claims = Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
        Long id = Long.valueOf(claims.getSubject());
        Long orgId = claims.get("org", Number.class).longValue();
        String email = claims.get("email", String.class);
        @SuppressWarnings("unchecked")
        Set<String> roles = ((java.util.List<String>) claims.get("roles", java.util.List.class))
                .stream().collect(Collectors.toUnmodifiableSet());
        return new AuthenticatedUser(id, orgId, email, roles);
    }

    public int refreshTokenTtlDays() {
        return jwtProperties.refreshTokenTtlDays();
    }
}
