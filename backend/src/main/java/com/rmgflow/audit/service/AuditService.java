package com.rmgflow.audit.service;

import com.rmgflow.audit.AuditLogRepository;
import com.rmgflow.audit.entity.AuditLog;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Document 15.8: single entry point every service calls to record a mandatory
 * audit event. Intentionally the ONLY write path to audit_logs in the codebase —
 * do not INSERT into audit_logs anywhere else, so this stays the one place that
 * needs review when the mandatory-audit-action list (Doc 15.8) changes.
 */
@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;

    public void record(String action, String entityType, Long entityId, Object previousValue, Object newValue, String reason) {
        AuditLog log = new AuditLog();
        log.setUserId(currentUserId());
        log.setAction(action);
        log.setEntityType(entityType);
        log.setEntityId(entityId);
        log.setPreviousValue(toJson(previousValue));
        log.setNewValue(toJson(newValue));
        log.setReason(reason);
        log.setIpAddress(currentIpAddress());
        auditLogRepository.save(log);
    }

    private JsonNode toJson(Object value) {
        return value == null ? null : objectMapper.valueToTree(value);
    }

    private Long currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof com.rmgflow.security.AuthenticatedUser principal)) {
            return null;
        }
        return principal.id();
    }

    private String currentIpAddress() {
        ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attrs == null) {
            return null;
        }
        HttpServletRequest request = attrs.getRequest();
        String forwarded = request.getHeader("X-Forwarded-For");
        return forwarded != null ? forwarded.split(",")[0].trim() : request.getRemoteAddr();
    }
}
