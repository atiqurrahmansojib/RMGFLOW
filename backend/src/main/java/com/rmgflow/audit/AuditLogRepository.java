package com.rmgflow.audit;

import com.rmgflow.audit.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    Page<AuditLog> findByEntityTypeAndEntityId(String entityType, Long entityId, Pageable pageable);

    /** Audit rows carry no organization column, so tenancy is derived from the acting user.
     *  Entity ids are global sequences; without this filter one org could read another's history. */
    @Query("select a from AuditLog a where a.entityType = :entityType and a.entityId = :entityId "
            + "and a.userId in (select u.id from User u where u.organization.id = :organizationId)")
    Page<AuditLog> findForOrganization(@Param("organizationId") Long organizationId,
                                       @Param("entityType") String entityType,
                                       @Param("entityId") Long entityId,
                                       Pageable pageable);
}
