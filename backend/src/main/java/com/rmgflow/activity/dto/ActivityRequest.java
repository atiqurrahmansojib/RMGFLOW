package com.rmgflow.activity.dto;

import com.rmgflow.activity.entity.ActivityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record ActivityRequest(
        @NotNull String entityType, @NotNull Long entityId, @NotNull ActivityType activityType,
        @NotNull Instant occurredAt, @NotBlank String content
) {
}
