package com.rmgflow.task.controller;

import com.rmgflow.task.dto.TaskRequest;
import com.rmgflow.task.dto.TaskResponse;
import com.rmgflow.task.entity.TaskStatus;
import com.rmgflow.task.service.TaskItemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskItemService taskItemService;

    @GetMapping
    @PreAuthorize("hasAuthority('TASK_VIEW')")
    public List<TaskResponse> listByEntity(@RequestParam String entityType, @RequestParam Long entityId) {
        return taskItemService.listByEntity(entityType, entityId);
    }

    @GetMapping("/my")
    @PreAuthorize("hasAuthority('TASK_VIEW')")
    public List<TaskResponse> myOpenTasks() {
        return taskItemService.myOpenTasks();
    }

    @PostMapping
    @PreAuthorize("hasAuthority('TASK_MANAGE')")
    public ResponseEntity<TaskResponse> create(@Valid @RequestBody TaskRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(taskItemService.create(request));
    }

    @PostMapping("/{id}/status")
    @PreAuthorize("hasAuthority('TASK_MANAGE')")
    public TaskResponse updateStatus(@PathVariable Long id, @RequestParam TaskStatus status) {
        return taskItemService.updateStatus(id, status);
    }
}
