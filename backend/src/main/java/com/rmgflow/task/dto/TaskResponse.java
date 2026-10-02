package com.rmgflow.task.dto;

import com.rmgflow.task.entity.TaskPriority;
import com.rmgflow.task.entity.TaskStatus;

import java.time.LocalDate;

public record TaskResponse(
        Long id, String entityType, Long entityId, String title, String description, Long assignedToId,
        TaskPriority priority, LocalDate dueDate, TaskStatus status, boolean overdue
) {
}
