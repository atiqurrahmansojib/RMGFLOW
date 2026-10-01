package com.rmgflow.identity.repository;

import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.ScopeType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentRepository extends JpaRepository<Assignment, Long> {
    List<Assignment> findByUserId(Long userId);
    boolean existsByUserIdAndScopeTypeAndScopeId(Long userId, ScopeType scopeType, Long scopeId);
}
