package com.rmgflow.identity.controller;

import com.rmgflow.identity.dto.CreateUserRequest;
import com.rmgflow.identity.dto.UserResponse;
import com.rmgflow.identity.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/** Document 5.2: user management restricted to SUPER_ADMIN, enforced server-side (Doc 15.2), not by hiding a button. */
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** Org-scoped user directory for assignee pickers; needs TASK_MANAGE (or Super Admin). */
    @GetMapping
    @PreAuthorize("hasAuthority('TASK_MANAGE') or hasRole('SUPER_ADMIN')")
    public java.util.List<com.rmgflow.identity.dto.UserSummaryResponse> list(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "true") boolean activeOnly) {
        return userService.listInOrganization(search, activeOnly);
    }

    @PostMapping
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.createUser(request));
    }
}
