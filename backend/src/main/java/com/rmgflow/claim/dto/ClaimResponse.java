package com.rmgflow.claim.dto;

import com.rmgflow.claim.entity.ClaimRaisedBy;
import com.rmgflow.claim.entity.ClaimStatus;
import com.rmgflow.claim.entity.ClaimType;

import java.math.BigDecimal;
import java.time.Instant;

public record ClaimResponse(
        Long id, Long orderId, Long shipmentId, ClaimRaisedBy raisedBy, ClaimType claimType, String description,
        BigDecimal claimedAmount, ClaimStatus status, String resolution, Instant createdAt, Instant resolvedAt
) {
}
