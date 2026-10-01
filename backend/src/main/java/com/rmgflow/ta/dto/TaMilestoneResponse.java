package com.rmgflow.ta.dto;

import com.rmgflow.ta.entity.TaMilestoneStatus;

import java.time.LocalDate;

public record TaMilestoneResponse(
        Long id, Long orderId, Long milestoneTypeId, String milestoneTypeName, int sequence,
        LocalDate plannedDate, LocalDate revisedDate, LocalDate actualDate,
        Long responsibleUserId, Long responsibleFactoryId, TaMilestoneStatus status,
        Long dependsOnMilestoneId, String delayReason, long delayDays
) {
}
