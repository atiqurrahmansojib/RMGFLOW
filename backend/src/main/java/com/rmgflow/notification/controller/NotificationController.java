package com.rmgflow.notification.controller;

import com.rmgflow.notification.dto.NotificationResponse;
import com.rmgflow.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 7 (#88): in-app notification feed. No @PreAuthorize permission gate
 * beyond authentication — a notification is inherently personal to the logged-in
 * user (NotificationService scopes every query to currentUser().id()). */
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public List<NotificationResponse> myNotifications() {
        return notificationService.myNotifications();
    }

    @PostMapping("/{id}/read")
    public void markRead(@PathVariable Long id) {
        notificationService.markRead(id);
    }
}
