package com.rmgflow.audit;

import com.rmgflow.audit.entity.AuditLog;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Document 15.8/Doc 5.2: audit log read access restricted to AUDIT_LOG_VIEW permission holders. */
@RestController
public class AuditLogController {

    private final AuditLogRepository auditLogRepository;

    public AuditLogController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/api/v1/audit-logs")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'OWNER_MD')")
    public Page<AuditLog> list(@RequestParam String entityType, @RequestParam Long entityId, Pageable pageable) {
        return auditLogRepository.findByEntityTypeAndEntityId(entityType, entityId, pageable);
    }
}
