package com.rmgflow.attachment.service;

import com.rmgflow.attachment.config.StorageProperties;
import com.rmgflow.common.ApiException;
import com.rmgflow.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * Document 15.4: "access via short-lived signed URLs generated per request after an
 * authorization check in the API." Implemented as a short-TTL signed token (same
 * mechanism as the access token, Doc 15.1/ADR-04, but a distinct `purpose` claim so
 * a stolen download link can never be replayed as an API access token or vice versa)
 * rather than a stateful token table — no extra schema, and verification needs no DB
 * round trip.
 */
@Service
@RequiredArgsConstructor
public class AttachmentDownloadTokenService {

    private static final String PURPOSE = "attachment_download";

    private final JwtProperties jwtProperties;
    private final StorageProperties storageProperties;

    public String issue(Long attachmentId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(attachmentId.toString())
                .claim("purpose", PURPOSE)
                .issuedAt(java.util.Date.from(now))
                .expiration(java.util.Date.from(now.plus(storageProperties.downloadTokenTtlMinutes(), ChronoUnit.MINUTES)))
                .signWith(key())
                .compact();
    }

    public Long verifyAndGetAttachmentId(String token) {
        try {
            Claims claims = Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
            if (!PURPOSE.equals(claims.get("purpose", String.class))) {
                throw new ApiException(HttpStatus.FORBIDDEN, "Invalid download token");
            }
            return Long.valueOf(claims.getSubject());
        } catch (JwtException | IllegalArgumentException e) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Invalid or expired download token");
        }
    }

    private SecretKey key() {
        return Keys.hmacShaKeyFor(jwtProperties.secret().getBytes(StandardCharsets.UTF_8));
    }
}
