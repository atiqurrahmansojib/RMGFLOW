package com.rmgflow.report.service;

import com.rmgflow.security.scope.AccessScope;

import java.time.LocalDate;
import java.util.Map;

/**
 * Validated, typed filter values for one report run. {@code organizationId} and
 * {@code scope} always come from the authenticated principal (and its assignments),
 * never from a request parameter, so every report query is tenant-scoped and, for
 * scoped roles, limited to the user's assigned buyers/factories.
 */
public record ReportParams(Long organizationId, AccessScope scope, Map<String, Object> values) {

    public LocalDate date(String key) {
        return (LocalDate) values.get(key);
    }

    public Long id(String key) {
        return (Long) values.get(key);
    }

    public String text(String key) {
        return (String) values.get(key);
    }
}
