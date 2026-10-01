package com.rmgflow.factory.dto;

import java.time.LocalDate;

public record FactoryCertificationResponse(
        Long id, Long factoryId, String certName, LocalDate issuedDate, LocalDate expiryDate,
        Long documentId, boolean expired
) {
}
