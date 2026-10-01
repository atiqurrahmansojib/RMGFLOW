package com.rmgflow.attachment.dto;

import java.time.Instant;

public record AttachmentResponse(
        Long id, String entityType, Long entityId, String fileName, String contentType,
        long sizeBytes, Long uploadedById, Instant uploadedAt
) {
}
