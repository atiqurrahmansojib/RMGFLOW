package com.rmgflow.identity.repository;

import com.rmgflow.identity.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmailIgnoreCase(String email);
    boolean existsByEmailIgnoreCase(String email);

    /** Security review fix: lets callers assign a user (e.g. as a merchandiser on an
     * inquiry) only when that user is within the caller's own organization. */
    Optional<User> findByIdAndOrganizationId(Long id, Long organizationId);
}
