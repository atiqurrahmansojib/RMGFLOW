package com.rmgflow.activity.dto;

import com.rmgflow.activity.entity.ActivityType;

import java.time.Instant;

public record ActivityResponse(
        Long id, String entityType, Long entityId, ActivityType activityType, Instant occurredAt, Long loggedById, String content
) {
}
