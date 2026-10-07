package com.rmgflow.report.service;

import com.rmgflow.security.scope.AccessScope;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;

import java.util.ArrayList;
import java.util.List;

/**
 * Tiny builder for report SQL: the base statement carries a {@code /*filters*}{@code /}
 * marker right after its organization-scoped WHERE clause, and each supplied filter
 * appends an AND condition there. Filters left empty add nothing, which avoids
 * Postgres's "could not determine data type of parameter" on {@code :p IS NULL} tricks.
 *
 * Every statement must also declare its object-level scope via {@link #scope} (Doc 5.3)
 * — {@link #sql()} refuses to render otherwise, so a new report can't silently skip it.
 */
final class ReportSql {

    static final String FILTERS = "/*filters*/";
    /** Bound to the user's assigned buyer ids inside a {@link #scope} buyer clause. */
    static final String SCOPE_BUYERS = ":scopeBuyerIds";
    /** Bound to the user's assigned factory ids inside a {@link #scope} factory clause. */
    static final String SCOPE_FACTORIES = ":scopeFactoryIds";

    private final String base;
    private final AccessScope scope;
    private final StringBuilder conditions = new StringBuilder();
    private final MapSqlParameterSource params = new MapSqlParameterSource();
    private boolean scopeApplied;

    ReportSql(String base, ReportParams p) {
        if (!base.contains(FILTERS)) {
            throw new IllegalArgumentException("Report SQL is missing the filters marker");
        }
        this.base = base;
        this.scope = p.scope();
        params.addValue("orgId", p.organizationId());
    }

    /** Appends {@code AND clause} binding {@code :name} to {@code value}, only when value is present. */
    ReportSql and(String clause, String name, Object value) {
        if (value != null) {
            conditions.append(" AND ").append(clause);
            params.addValue(name, value);
        }
        return this;
    }

    /** Appends a parameterless condition, only when {@code apply} is true. */
    ReportSql andIf(boolean apply, String clause) {
        if (apply) {
            conditions.append(" AND ").append(clause);
        }
        return this;
    }

    /**
     * Object-level scope: for a scoped user appends {@code AND (buyerClause OR factoryClause)},
     * where each clause references {@link #SCOPE_BUYERS} / {@link #SCOPE_FACTORIES}. A clause is
     * null when the report's rows have no such dimension. A clause whose allowed set is empty is
     * dropped (no {@code IN ()}), and if nothing remains the condition is {@code FALSE} — an
     * unassigned user sees no rows, never all rows.
     */
    ReportSql scope(String buyerClause, String factoryClause) {
        scopeApplied = true;
        if (scope.unrestricted()) {
            return this;
        }
        List<String> parts = new ArrayList<>();
        if (buyerClause != null && !scope.buyerIds().isEmpty()) {
            parts.add(buyerClause);
            params.addValue("scopeBuyerIds", scope.buyerIds());
        }
        if (factoryClause != null && !scope.factoryIds().isEmpty()) {
            parts.add(factoryClause);
            params.addValue("scopeFactoryIds", scope.factoryIds());
        }
        conditions.append(" AND ").append(parts.isEmpty() ? "FALSE" : "(" + String.join(" OR ", parts) + ")");
        return this;
    }

    String sql() {
        if (!scopeApplied) {
            throw new IllegalStateException("Report SQL must declare its object-level scope");
        }
        return base.replace(FILTERS, conditions.toString());
    }

    MapSqlParameterSource params() {
        return params;
    }
}
