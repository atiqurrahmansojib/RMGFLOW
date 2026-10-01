package com.rmgflow.factory.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record FactoryCertificationRequest(
        @NotBlank String certName, LocalDate issuedDate, LocalDate expiryDate, Long documentId
) {
}
