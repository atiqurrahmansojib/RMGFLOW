package com.rmgflow.activity.repository;

import com.rmgflow.activity.entity.Activity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActivityRepository extends JpaRepository<Activity, Long> {
    List<Activity> findByEntityTypeAndEntityIdAndOrganizationIdOrderByOccurredAtDesc(String entityType, Long entityId, Long organizationId);
}
