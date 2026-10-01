package com.rmgflow.identity.repository;

import com.rmgflow.identity.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.Optional;
import java.util.Set;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByName(String name);

    /**
     * Document 5.3: resolves role names (trusted, from the signed JWT) to the
     * permission codes they grant, via the role_permissions mapping — the
     * actual authorization decision is always made against this DB-backed
     * mapping, never against a permission list embedded in the token itself.
     */
    @Query("select p.code from Role r join r.permissions p where r.name in :roleNames")
    Set<String> findPermissionCodesByRoleNames(@Param("roleNames") Collection<String> roleNames);
}
