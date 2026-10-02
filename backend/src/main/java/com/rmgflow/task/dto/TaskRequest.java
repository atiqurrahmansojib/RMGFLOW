package com.rmgflow.task.dto;

import com.rmgflow.task.entity.TaskPriority;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record TaskRequest(
        @NotNull String entityType, @NotNull Long entityId, @NotBlank String title, String description,
        Long assignedToId, @NotNull TaskPriority priority, LocalDate dueDate
) {
}
