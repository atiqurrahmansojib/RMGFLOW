package com.rmgflow.task.repository;

import com.rmgflow.task.entity.TaskItem;
import com.rmgflow.task.entity.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TaskItemRepository extends JpaRepository<TaskItem, Long> {
    List<TaskItem> findByEntityTypeAndEntityIdAndOrganizationId(String entityType, Long entityId, Long organizationId);

    List<TaskItem> findByAssignedTo_IdAndOrganizationIdAndStatusNot(Long assignedToId, Long organizationId, TaskStatus excludedStatus);

    List<TaskItem> findByAssignedTo_IdAndOrganizationIdAndStatusNotAndDueDateLessThanEqual(
            Long assignedToId, Long organizationId, TaskStatus excludedStatus, LocalDate dueDate);

    Optional<TaskItem> findByIdAndOrganizationId(Long id, Long organizationId);
}
