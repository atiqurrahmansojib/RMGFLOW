package com.rmgflow.security.scope;

import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.repository.AssignmentRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

/**
 * Resolves the caller's {@link AccessScope} from their roles and {@code assignments}
 * (Doc 5.1/5.3). Any unrestricted role wins; otherwise buyer assignments count only
 * for buyer-scoped roles and factory assignments only for factory-scoped roles.
 */
@Service
@RequiredArgsConstructor
public class AccessScopeService {

    /** Doc 5.1: full (organization-wide) read. */
    public static final Set<String> UNRESTRICTED_ROLES =
            Set.of("SUPER_ADMIN", "OWNER_MD", "GENERAL_MANAGER", "ACCOUNTS_FINANCE", "MANAGEMENT_VIEWER");
    /** Doc 5.1: roles scoped to their assigned buyers ("own buyers"). */
    public static final Set<String> BUYER_SCOPED_ROLES =
            Set.of("SENIOR_MERCHANDISER", "JUNIOR_MERCHANDISER", "SAMPLING_COORDINATOR", "COMMERCIAL_EXECUTIVE");
    /** Doc 5.1: roles scoped to their assigned factories ("own factory"). */
    public static final Set<String> FACTORY_SCOPED_ROLES =
            Set.of("PRODUCTION_FOLLOWUP", "FACTORY_COORDINATOR", "QUALITY_INSPECTOR", "SAMPLING_COORDINATOR");

    private final AssignmentRepository assignmentRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public AccessScope current() {
        AuthenticatedUser user = currentUser();
        Set<String> roles = user.roles() == null ? Set.of() : user.roles();
        if (roles.stream().anyMatch(UNRESTRICTED_ROLES::contains)) {
            return AccessScope.UNRESTRICTED;
        }
        boolean byBuyer = roles.stream().anyMatch(BUYER_SCOPED_ROLES::contains);
        boolean byFactory = roles.stream().anyMatch(FACTORY_SCOPED_ROLES::contains);
        Set<Long> buyerIds = new HashSet<>();
        Set<Long> factoryIds = new HashSet<>();
        for (Assignment assignment : assignmentRepository.findByUserId(user.id())) {
            if (assignment.getScopeType() == ScopeType.BUYER && byBuyer) {
                buyerIds.add(assignment.getScopeId());
            } else if (assignment.getScopeType() == ScopeType.FACTORY && byFactory) {
                factoryIds.add(assignment.getScopeId());
            }
        }
        return AccessScope.scoped(byBuyer, buyerIds, factoryIds);
    }

    /**
     * A buyer-scoped user who creates a buyer (Doc 5.2 "Create/Edit own") is assigned
     * to it, otherwise their own new buyer would immediately vanish from their lists.
     */
    @Transactional
    public void assignCreatorToBuyer(Long buyerId) {
        AccessScope scope = current();
        if (scope.unrestricted() || !scope.buyerScoped()) {
            return;
        }
        AuthenticatedUser user = currentUser();
        if (assignmentRepository.existsByUserIdAndScopeTypeAndScopeId(user.id(), ScopeType.BUYER, buyerId)) {
            return;
        }
        Assignment assignment = new Assignment();
        assignment.setUser(userRepository.getReferenceById(user.id()));
        assignment.setScopeType(ScopeType.BUYER);
        assignment.setScopeId(buyerId);
        assignmentRepository.save(assignment);
    }

    private static AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
