package com.rmgflow.factory.dto;

import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record FactoryBuyerApprovalRequest(
        @NotNull Long buyerId, @NotNull FactoryBuyerApprovalStatus status, LocalDate approvedDate, LocalDate expiryDate
) {
}
