package com.rmgflow.audit;

import com.rmgflow.audit.entity.AuditLog;
import com.rmgflow.security.AuthenticatedUser;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Document 15.8/Doc 5.2: audit log read access restricted to AUDIT_LOG_VIEW permission holders
 *  (Super Admin, Owner/MD and General Manager per the Doc 5 matrix), scoped to the caller's org. */
@RestController
public class AuditLogController {

    private final AuditLogRepository auditLogRepository;

    public AuditLogController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/api/v1/audit-logs")
    @PreAuthorize("hasAuthority('AUDIT_LOG_VIEW')")
    public Page<AuditLog> list(@AuthenticationPrincipal AuthenticatedUser user,
                               @RequestParam String entityType, @RequestParam Long entityId, Pageable pageable) {
        return auditLogRepository.findForOrganization(user.organizationId(), entityType, entityId, pageable);
    }
}
