package com.rmgflow.notification.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.notification.dto.NotificationResponse;
import com.rmgflow.notification.entity.Notification;
import com.rmgflow.notification.repository.NotificationRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 8.9/13: the dispatch sink other services (T&A overdue scan, etc.) write
 * to — see TaMilestoneNotificationJob for the first real automation wired to this. */
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    @Transactional
    public void notify(Long userId, String entityType, Long entityId, String message) {
        if (userId == null) return; // no responsible user to notify — nothing to do
        Notification notification = new Notification();
        notification.setUser(userRepository.getReferenceById(userId));
        notification.setEntityType(entityType);
        notification.setEntityId(entityId);
        notification.setMessage(message);
        notificationRepository.save(notification);
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> myNotifications() {
        return notificationRepository.findByUser_IdOrderByCreatedAtDesc(currentUser().id()).stream().map(this::toResponse).toList();
    }

    @Transactional
    public void markRead(Long notificationId) {
        Notification notification = notificationRepository.findByIdAndUser_Id(notificationId, currentUser().id())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Notification not found"));
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    private NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(notification.getId(), notification.getEntityType(), notification.getEntityId(),
                notification.getMessage(), notification.isRead(), notification.getCreatedAt());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
