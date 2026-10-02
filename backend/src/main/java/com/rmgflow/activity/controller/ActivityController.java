package com.rmgflow.activity.controller;

import com.rmgflow.activity.dto.ActivityRequest;
import com.rmgflow.activity.dto.ActivityResponse;
import com.rmgflow.activity.service.ActivityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/activities")
@RequiredArgsConstructor
public class ActivityController {

    private final ActivityService activityService;

    @GetMapping
    @PreAuthorize("hasAuthority('ACTIVITY_VIEW')")
    public List<ActivityResponse> list(@RequestParam String entityType, @RequestParam Long entityId) {
        return activityService.list(entityType, entityId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ACTIVITY_MANAGE')")
    public ResponseEntity<ActivityResponse> log(@Valid @RequestBody ActivityRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(activityService.log(request));
    }
}
