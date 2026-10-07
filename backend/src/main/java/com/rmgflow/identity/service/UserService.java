package com.rmgflow.identity.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.dto.CreateUserRequest;
import com.rmgflow.identity.dto.UserResponse;
import com.rmgflow.identity.entity.Role;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

/** Document 21 P1-T1/P1-T2: user creation is Super Admin only (Doc 5.2), always within the caller's organization. */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        if (userRepository.existsByEmailIgnoreCase(request.email())) {
            throw new ApiException(HttpStatus.CONFLICT, "A user with this email already exists");
        }

        Set<Role> roles = request.roleNames().stream()
                .map(name -> roleRepository.findByName(name)
                        .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Unknown role: " + name)))
                .collect(Collectors.toCollection(HashSet::new));

        User user = new User();
        user.setOrganization(organizationRepository.getReferenceById(currentOrganizationId()));
        user.setEmail(request.email());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setFullName(request.fullName());
        user.setPhone(request.phone());
        user.setRoles(roles);
        user = userRepository.save(user);

        auditService.record("USER_CREATE", "User", user.getId(), null, toResponse(user), null);
        return toResponse(user);
    }

    /** Org-scoped user directory for pickers (task assignee, Doc 7); optional name/email filter. */
    @Transactional(readOnly = true)
    public java.util.List<com.rmgflow.identity.dto.UserSummaryResponse> listInOrganization(String search, boolean activeOnly) {
        String needle = search == null ? "" : search.trim().toLowerCase();
        return userRepository.findByOrganizationIdOrderByFullNameAsc(currentOrganizationId()).stream()
                .filter(u -> !activeOnly || u.isActive())
                .filter(u -> needle.isEmpty() || u.getFullName().toLowerCase().contains(needle)
                        || u.getEmail().toLowerCase().contains(needle))
                .map(u -> new com.rmgflow.identity.dto.UserSummaryResponse(u.getId(), u.getFullName(), u.getEmail(),
                        u.getRoles().stream().map(Role::getName).collect(Collectors.toUnmodifiableSet()), u.isActive()))
                .toList();
    }

    private Long currentOrganizationId() {
        AuthenticatedUser principal = (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return principal.organizationId();
    }

    private UserResponse toResponse(User user) {
        Set<String> roleNames = user.getRoles().stream().map(Role::getName).collect(Collectors.toUnmodifiableSet());
        return new UserResponse(user.getId(), user.getEmail(), user.getFullName(), user.getPhone(), user.isActive(), roleNames);
    }
}
