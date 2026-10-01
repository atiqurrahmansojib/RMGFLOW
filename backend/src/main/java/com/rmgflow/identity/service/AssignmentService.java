package com.rmgflow.identity.service;

import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.repository.AssignmentRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Document 5.3 (P1-T4): object-level authorization layered on top of role/permission
 * checks. A role granting e.g. ORDER_CREATE is necessary but not sufficient — the
 * acting user must also be assigned to the specific buyer/factory the resource
 * belongs to, unless their role is exempted (GM/Owner see everything, enforced by
 * callers checking for those roles before calling this, not by this method).
 */
@Service
@RequiredArgsConstructor
public class AssignmentService {

    private final AssignmentRepository assignmentRepository;

    public boolean hasBuyerAccess(AuthenticatedUser user, Long buyerId) {
        return assignmentRepository.existsByUserIdAndScopeTypeAndScopeId(user.id(), ScopeType.BUYER, buyerId);
    }

    public boolean hasFactoryAccess(AuthenticatedUser user, Long factoryId) {
        return assignmentRepository.existsByUserIdAndScopeTypeAndScopeId(user.id(), ScopeType.FACTORY, factoryId);
    }
}
