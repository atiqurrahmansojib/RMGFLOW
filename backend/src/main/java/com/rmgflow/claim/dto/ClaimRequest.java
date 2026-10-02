package com.rmgflow.claim.dto;

import com.rmgflow.claim.entity.ClaimRaisedBy;
import com.rmgflow.claim.entity.ClaimType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ClaimRequest(
        Long shipmentId, @NotNull ClaimRaisedBy raisedBy, @NotNull ClaimType claimType,
        @NotBlank String description, BigDecimal claimedAmount
) {
}
