package com.rmgflow.claim.dto;

import com.rmgflow.claim.entity.ClaimStatus;
import jakarta.validation.constraints.NotNull;

public record ClaimResolutionRequest(@NotNull ClaimStatus status, String resolution) {
}
