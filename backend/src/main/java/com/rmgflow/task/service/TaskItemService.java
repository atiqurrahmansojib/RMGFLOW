package com.rmgflow.task.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.task.dto.TaskRequest;
import com.rmgflow.task.dto.TaskResponse;
import com.rmgflow.task.entity.TaskItem;
import com.rmgflow.task.entity.TaskStatus;
import com.rmgflow.task.repository.TaskItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/** Document 21: tasks always attached to a real business entity, never free-floating. */
@Service
@RequiredArgsConstructor
public class TaskItemService {

    private final TaskItemRepository taskItemRepository;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;

    @Transactional
    public TaskResponse create(TaskRequest request) {
        TaskItem task = new TaskItem();
        task.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        task.setEntityType(request.entityType());
        task.setEntityId(request.entityId());
        task.setTitle(request.title());
        task.setDescription(request.description());
        task.setAssignedTo(resolveAssignee(request.assignedToId()));
        task.setPriority(request.priority());
        task.setDueDate(request.dueDate());
        task.setCreatedBy(userRepository.getReferenceById(currentUser().id()));
        task = taskItemRepository.save(task);
        return toResponse(task);
    }

    /** Re-assigns (or, with null, un-assigns) a task — the edit path of the assignee picker. */
    @Transactional
    public TaskResponse reassign(Long taskId, Long userId) {
        TaskItem task = findInCurrentOrganization(taskId);
        task.setAssignedTo(resolveAssignee(userId));
        return toResponse(taskItemRepository.save(task));
    }

    /** Assignee must be an active user of the caller's own organization (no cross-tenant ids). */
    private com.rmgflow.identity.entity.User resolveAssignee(Long userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findByIdAndOrganizationId(userId, currentUser().organizationId())
                .filter(com.rmgflow.identity.entity.User::isActive)
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Assignee must be an active user of your organization"));
    }

    @Transactional
    public TaskResponse updateStatus(Long taskId, TaskStatus status) {
        TaskItem task = findInCurrentOrganization(taskId);
        task.setStatus(status);
        task = taskItemRepository.save(task);
        return toResponse(task);
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> listByEntity(String entityType, Long entityId) {
        return taskItemRepository.findByEntityTypeAndEntityIdAndOrganizationId(entityType, entityId, currentUser().organizationId())
                .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> myOpenTasks() {
        AuthenticatedUser user = currentUser();
        return taskItemRepository.findByAssignedTo_IdAndOrganizationIdAndStatusNot(user.id(), user.organizationId(), TaskStatus.CANCELLED)
                .stream().filter(t -> t.getStatus() != TaskStatus.DONE).map(this::toResponse).toList();
    }

    /** Document 14.9: feeds the "My Day" dashboard. */
    @Transactional(readOnly = true)
    public List<TaskResponse> myOverdueTasks() {
        AuthenticatedUser user = currentUser();
        return taskItemRepository.findByAssignedTo_IdAndOrganizationIdAndStatusNotAndDueDateLessThanEqual(
                user.id(), user.organizationId(), TaskStatus.DONE, LocalDate.now()).stream().map(this::toResponse).toList();
    }

    private TaskItem findInCurrentOrganization(Long taskId) {
        return taskItemRepository.findByIdAndOrganizationId(taskId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Task not found"));
    }

    private TaskResponse toResponse(TaskItem task) {
        boolean overdue = task.getDueDate() != null && task.getDueDate().isBefore(LocalDate.now())
                && task.getStatus() != TaskStatus.DONE && task.getStatus() != TaskStatus.CANCELLED;
        return new TaskResponse(task.getId(), task.getEntityType(), task.getEntityId(), task.getTitle(), task.getDescription(),
                task.getAssignedTo() != null ? task.getAssignedTo().getId() : null, task.getPriority(), task.getDueDate(),
                task.getStatus(), overdue, task.getAssignedTo() != null ? task.getAssignedTo().getFullName() : null);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
