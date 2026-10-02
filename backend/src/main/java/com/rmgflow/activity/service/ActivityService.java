package com.rmgflow.activity.service;

import com.rmgflow.activity.dto.ActivityRequest;
import com.rmgflow.activity.dto.ActivityResponse;
import com.rmgflow.activity.entity.Activity;
import com.rmgflow.activity.repository.ActivityRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 20/FR-150-151: cross-cutting, attachable to any entity — not a per-module
 * comment table. Known limitation shared with the attachment module (Doc 21 P3-T3
 * javadoc): no per-entity-type existence/tenant check on (entityType, entityId)
 * itself, only on this row's own organization_id. */
@Service
@RequiredArgsConstructor
public class ActivityService {

    private final ActivityRepository activityRepository;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;

    @Transactional
    public ActivityResponse log(ActivityRequest request) {
        Activity activity = new Activity();
        activity.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        activity.setEntityType(request.entityType());
        activity.setEntityId(request.entityId());
        activity.setActivityType(request.activityType());
        activity.setOccurredAt(request.occurredAt());
        activity.setContent(request.content());
        activity.setLoggedBy(userRepository.getReferenceById(currentUser().id()));
        activity = activityRepository.save(activity);
        return toResponse(activity);
    }

    @Transactional(readOnly = true)
    public List<ActivityResponse> list(String entityType, Long entityId) {
        return activityRepository.findByEntityTypeAndEntityIdAndOrganizationIdOrderByOccurredAtDesc(
                entityType, entityId, currentUser().organizationId()).stream().map(this::toResponse).toList();
    }

    private ActivityResponse toResponse(Activity activity) {
        return new ActivityResponse(activity.getId(), activity.getEntityType(), activity.getEntityId(),
                activity.getActivityType(), activity.getOccurredAt(),
                activity.getLoggedBy() != null ? activity.getLoggedBy().getId() : null, activity.getContent());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
