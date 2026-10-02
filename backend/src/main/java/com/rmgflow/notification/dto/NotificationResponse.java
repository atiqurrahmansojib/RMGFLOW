package com.rmgflow.notification.dto;

import java.time.Instant;

public record NotificationResponse(Long id, String entityType, Long entityId, String message, boolean read, Instant createdAt) {
}
