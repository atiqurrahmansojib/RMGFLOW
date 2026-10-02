package com.rmgflow.quality.dto;

import com.rmgflow.quality.entity.CapaStatus;

import java.time.Instant;

public record CapaRecordResponse(
        Long id, Long defectId, Long inspectionId, String description, String correctiveAction,
        String preventiveAction, String factoryResponse, CapaStatus status, Instant createdAt, Instant closedAt
) {
}
