package com.rmgflow.document.dto;

import com.rmgflow.document.entity.DocumentEntityType;
import com.rmgflow.document.entity.DocumentStatus;

import java.time.Instant;
import java.time.LocalDate;

public record CommercialDocumentResponse(
        Long id, DocumentEntityType entityType, Long entityId, Long documentTypeId, int versionNo,
        Long fileAttachmentId, DocumentStatus status, Long ownerId, Instant uploadedAt, LocalDate expiryDate, boolean expired
) {
}
