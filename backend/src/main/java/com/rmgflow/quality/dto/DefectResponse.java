package com.rmgflow.quality.dto;

public record DefectResponse(Long id, Long inspectionId, Long defectTypeId, int quantity, String severity, Long photoDocumentId) {
}
