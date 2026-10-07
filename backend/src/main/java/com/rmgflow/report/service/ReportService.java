package com.rmgflow.report.service;

import com.rmgflow.security.scope.AccessScope;

import com.rmgflow.common.ApiException;
import com.rmgflow.security.scope.AccessScopeService;
import com.rmgflow.report.dto.ReportColumn;
import com.rmgflow.report.dto.ReportDefinitionResponse;
import com.rmgflow.report.dto.ReportFilterResponse;
import com.rmgflow.report.dto.ReportResultResponse;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.time.temporal.TemporalAccessor;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Document 14: runs registry reports for the current user's organization.
 *
 * Access rule per report: REPORT_VIEW (checked at the controller) AND the report's
 * module permission (or REPORT_VIEW_ALL) AND, for financial reports,
 * REPORT_FINANCIAL_VIEW. The catalog only lists reports the user can run.
 *
 * Row-level rule (Doc 5.1 "Reports/dashboards" + 5.3): Super Admin, Owner, GM,
 * Accounts and Management Viewer see the whole organization; every other role sees
 * only rows for the buyers/factories it is assigned to in {@code assignments}
 * (merchandisers by buyer, production follow-up / factory coordinator by factory).
 * Run and CSV/PDF export share this path, so exports are scoped identically.
 */
@Service
@RequiredArgsConstructor
public class ReportService {

    static final String REPORT_VIEW_ALL = "REPORT_VIEW_ALL";
    static final String REPORT_FINANCIAL_VIEW = "REPORT_FINANCIAL_VIEW";

    private final ReportRegistry registry;
    private final DataSource dataSource;
    private final AccessScopeService accessScopeService;

    public List<ReportDefinitionResponse> list() {
        Set<String> authorities = currentAuthorities();
        return registry.all().stream()
                .filter(def -> canRun(def, authorities))
                .map(def -> new ReportDefinitionResponse(def.code(), def.name(), def.category(), def.description(), def.filters()))
                .toList();
    }

    @Transactional(readOnly = true)
    public ReportResultResponse run(String code, Map<String, String> rawFilters) {
        ReportDefinition definition = authorizedDefinition(code);
        AccessScope scope = currentScope();
        Map<String, Object> values = parseFilters(definition, rawFilters);
        requireFiltersInScope(values, scope);
        ReportParams params = new ReportParams(currentUser().organizationId(), scope, values);
        ReportData data = definition.query().run(params);
        List<Map<String, Object>> rows = data.rows().stream().map(row -> normalizeRow(definition.columns(), row)).toList();
        return new ReportResultResponse(definition.code(), definition.name(), OffsetDateTime.now(), definition.columns(),
                rows, data.summary());
    }

    /**
     * Human-readable "label: value" lines for the filters actually applied — used in
     * export headers. Buyer/factory ids are resolved to names within the caller's
     * organization only (an id from another tenant simply resolves to nothing), and an
     * id outside a scoped user's assignments is never resolved to a name.
     */
    @Transactional(readOnly = true)
    public List<String> describeFilters(String code, Map<String, String> rawFilters) {
        ReportDefinition definition = authorizedDefinition(code);
        Map<String, Object> values = parseFilters(definition, rawFilters);
        AccessScope scope = currentScope();
        requireFiltersInScope(values, scope);
        Long organizationId = currentUser().organizationId();
        NamedParameterJdbcTemplate jdbc = new NamedParameterJdbcTemplate(dataSource);
        return definition.filters().stream()
                .filter(filter -> values.containsKey(filter.key()))
                .map(filter -> {
                    Object value = values.get(filter.key());
                    String display = switch (filter.type()) {
                        case "buyer" -> scope.unrestricted() || scope.buyerIds().contains(value)
                                ? lookupName(jdbc, "buyers", (Long) value, organizationId) : "#" + value;
                        case "factory" -> scope.unrestricted() || scope.factoryIds().contains(value)
                                ? lookupName(jdbc, "factories", (Long) value, organizationId) : "#" + value;
                        default -> value.toString();
                    };
                    return filter.label() + ": " + display;
                })
                .toList();
    }

    private ReportDefinition authorizedDefinition(String code) {
        ReportDefinition definition = registry.find(code)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Unknown report: " + code));
        if (!canRun(definition, currentAuthorities())) {
            throw new AccessDeniedException("Not permitted to run report " + code);
        }
        return definition;
    }

    /** Doc 5.1/5.3 object-level scope, shared with every list/get endpoint. */
    private AccessScope currentScope() {
        return accessScopeService.current();
    }

    /**
     * Explicitly probing a buyer/factory outside the caller's assignments is refused (403)
     * rather than silently returning nothing. The one exception: a user scoped on both
     * dimensions may narrow by a buyer they reach only through an assigned factory (and
     * vice versa) — the SQL scope condition still applies, so nothing leaks either way.
     */
    private static void requireFiltersInScope(Map<String, Object> values, AccessScope scope) {
        if (scope.unrestricted()) {
            return;
        }
        Object buyerId = values.get("buyerId");
        if (buyerId != null && !scope.buyerIds().contains(buyerId) && scope.factoryIds().isEmpty()) {
            throw new AccessDeniedException("Not permitted to report on this buyer");
        }
        Object factoryId = values.get("factoryId");
        if (factoryId != null && !scope.factoryIds().contains(factoryId) && scope.buyerIds().isEmpty()) {
            throw new AccessDeniedException("Not permitted to report on this factory");
        }
    }

    static boolean canRun(ReportDefinition definition, Set<String> authorities) {
        if (definition.financial() && !authorities.contains(REPORT_FINANCIAL_VIEW)) {
            return false;
        }
        return authorities.contains(REPORT_VIEW_ALL) || authorities.contains(definition.moduleAuthority());
    }

    /** Validates and types the declared filters; undeclared request parameters are ignored. */
    private Map<String, Object> parseFilters(ReportDefinition definition, Map<String, String> raw) {
        Map<String, Object> values = new HashMap<>();
        for (ReportFilterResponse filter : definition.filters()) {
            String value = raw.get(filter.key());
            if (value == null || value.isBlank()) {
                if (filter.required()) {
                    throw new ApiException(HttpStatus.BAD_REQUEST, "Filter '" + filter.key() + "' is required");
                }
                continue;
            }
            value = value.trim();
            try {
                Object typed = switch (filter.type()) {
                    case "date" -> LocalDate.parse(value);
                    case "buyer", "factory" -> Long.valueOf(value);
                    case "status" -> {
                        String upper = value.toUpperCase();
                        if (filter.options() != null && !filter.options().contains(upper)) {
                            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid value for '" + filter.key()
                                    + "'; allowed: " + String.join(", ", filter.options()));
                        }
                        yield upper;
                    }
                    default -> value;
                };
                values.put(filter.key(), typed);
            } catch (DateTimeParseException ex) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Filter '" + filter.key() + "' must be a date (yyyy-MM-dd)");
            } catch (NumberFormatException ex) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Filter '" + filter.key() + "' must be a numeric id");
            }
        }
        LocalDate from = (LocalDate) values.get("from");
        LocalDate to = (LocalDate) values.get("to");
        if (from != null && to != null && from.isAfter(to)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "'from' must not be after 'to'");
        }
        return values;
    }

    /** Keeps only declared columns, in declared order, and formats values by column type. */
    private static Map<String, Object> normalizeRow(List<ReportColumn> columns, Map<String, Object> row) {
        Map<String, Object> out = new LinkedHashMap<>();
        for (ReportColumn column : columns) {
            out.put(column.key(), normalizeValue(column.type(), row.get(column.key())));
        }
        return out;
    }

    private static Object normalizeValue(String type, Object value) {
        if (value == null) {
            return null;
        }
        return switch (type) {
            case "date" -> {
                if (value instanceof java.sql.Date sqlDate) {
                    yield sqlDate.toLocalDate().toString();
                }
                if (value instanceof Timestamp timestamp) {
                    yield timestamp.toLocalDateTime().toLocalDate().toString();
                }
                if (value instanceof TemporalAccessor temporal) {
                    yield LocalDate.from(temporal).toString();
                }
                yield value.toString();
            }
            case "money", "percent" -> {
                BigDecimal decimal = Summaries.toDecimal(value);
                yield decimal == null ? value : decimal.setScale(2, RoundingMode.HALF_UP);
            }
            case "number" -> {
                BigDecimal decimal = Summaries.toDecimal(value);
                if (decimal == null) {
                    yield value;
                }
                yield decimal.stripTrailingZeros().scale() <= 0 ? (Object) decimal.longValue() : decimal.setScale(2, RoundingMode.HALF_UP);
            }
            default -> value.toString();
        };
    }

    private static String lookupName(NamedParameterJdbcTemplate jdbc, String table, Long id, Long organizationId) {
        List<String> names = jdbc.queryForList("SELECT name FROM " + table + " WHERE id = :id AND organization_id = :orgId",
                Map.of("id", id, "orgId", organizationId), String.class);
        return names.isEmpty() ? "#" + id : names.get(0);
    }

    private static Set<String> currentAuthorities() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toSet());
    }

    private static AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
