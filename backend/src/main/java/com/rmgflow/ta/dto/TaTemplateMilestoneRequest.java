package com.rmgflow.ta.dto;

import jakarta.validation.constraints.NotNull;

public record TaTemplateMilestoneRequest(
        @NotNull Long milestoneTypeId,
        @NotNull Integer sequence,
        @NotNull Integer offsetDaysFromExfactory,
        Long dependsOnMilestoneId
) {
}
