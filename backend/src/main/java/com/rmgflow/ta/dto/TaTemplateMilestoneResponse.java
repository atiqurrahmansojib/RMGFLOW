package com.rmgflow.ta.dto;

public record TaTemplateMilestoneResponse(
        Long id, Long templateId, Long milestoneTypeId, int sequence, int offsetDaysFromExfactory, Long dependsOnMilestoneId
) {
}
