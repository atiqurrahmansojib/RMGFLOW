package com.rmgflow.document.dto;

import com.rmgflow.document.entity.DocumentEntityType;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record CommercialDocumentRequest(
        @NotNull DocumentEntityType entityType,
        @NotNull Long entityId,
        @NotNull Long documentTypeId,
        @NotNull Long fileAttachmentId,
        LocalDate expiryDate
) {
}
