package com.rmgflow.factory.dto;

import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;

import java.time.LocalDate;

public record FactoryBuyerApprovalResponse(
        Long id, Long factoryId, Long buyerId, FactoryBuyerApprovalStatus status,
        LocalDate approvedDate, LocalDate expiryDate
) {
}
