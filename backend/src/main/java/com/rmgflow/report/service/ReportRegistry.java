package com.rmgflow.report.service;

import com.rmgflow.security.scope.AccessScope;

import com.rmgflow.report.dto.ReportColumn;
import com.rmgflow.report.dto.ReportFilterResponse;
import com.rmgflow.report.dto.ReportSummaryItem;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static com.rmgflow.report.service.Summaries.*;

/**
 * Document 14: the single registry of report definitions. Each report is one
 * read-only SQL query over the existing module tables, always scoped by
 * {@code :orgId} (taken from the authenticated principal — never from the request)
 * and by the user's object-level {@link AccessScope} (assigned buyers/factories, Doc
 * 5.3), plus a summary block computed from the same scoped rows.
 *
 * Statuses that the T&A module derives at read time (Doc 9.5: OVERDUE/CRITICAL_DELAY)
 * are re-derived here in SQL with the same rule and the same 3-day threshold.
 */
@Component
public class ReportRegistry {

    /** Doc 9.5 default critical-delay threshold (kept in sync with TaMilestoneService). */
    private static final int CRITICAL_DELAY_DAYS = 3;
    /** Doc 9.1 recommendation: a soft margin floor used only to flag rows, never to block. */
    private static final int MARGIN_FLOOR_PERCENT = 10;
    /** Document expiry warning window. */
    private static final int EXPIRY_WARNING_DAYS = 30;

    private static final List<String> ORDER_STATUSES =
            List.of("CONFIRMED", "IN_PROGRESS", "PARTIALLY_SHIPPED", "SHIPPED", "CLOSED", "CANCELLED");
    private static final String ACTIVE_ORDER_STATUSES = "('CONFIRMED','IN_PROGRESS','PARTIALLY_SHIPPED')";

    /** Order belongs to the given factory when any of its lines is produced there. */
    private static final String ORDER_HAS_FACTORY =
            "EXISTS (SELECT 1 FROM order_items oif WHERE oif.order_id = o.id AND oif.factory_id = :factoryId)";
    /** Object-level scope (Doc 5.3) for order-based rows: assigned buyer, or any line made in an assigned factory. */
    private static final String ORDER_SCOPE_BUYER = "o.buyer_id IN (:scopeBuyerIds)";
    private static final String ORDER_SCOPE_FACTORY =
            "EXISTS (SELECT 1 FROM order_items osf WHERE osf.order_id = o.id AND osf.factory_id IN (:scopeFactoryIds))";
    private static final String ORDER_FACTORIES =
            "(SELECT string_agg(DISTINCT f.name, ', ') FROM order_items oi JOIN factories f ON f.id = oi.factory_id WHERE oi.order_id = o.id)";

    private final NamedParameterJdbcTemplate jdbc;
    private final Map<String, ReportDefinition> definitions = new LinkedHashMap<>();

    public ReportRegistry(DataSource dataSource) {
        this.jdbc = new NamedParameterJdbcTemplate(dataSource);
        register(buyerSummary());
        register(inquiryPipeline());
        register(costingMargin());
        register(sampleApproval());
        register(orderStatus());
        register(orderDelay());
        register(productionProgress());
        register(factoryPerformance());
        register(qualityInspections());
        register(defectAnalysis());
        register(shipmentStatus());
        register(documentExpiry());
        register(receivablesPayables());
        register(orderProfitability());
        register(claimsSummary());
    }

    public Collection<ReportDefinition> all() {
        return definitions.values();
    }

    public Optional<ReportDefinition> find(String code) {
        return Optional.ofNullable(definitions.get(code));
    }

    private void register(ReportDefinition definition) {
        definitions.put(definition.code(), definition);
    }

    // ---------------------------------------------------------------- 14.1 Buyer

    private ReportDefinition buyerSummary() {
        String sql = """
                SELECT b.code AS buyer_code, b.name AS buyer_name, b.country, o.currency,
                       COUNT(o.id) AS orders,
                       COUNT(o.id) FILTER (WHERE o.status IN %s) AS active_orders,
                       COALESCE(SUM(q.qty), 0) AS total_qty,
                       COALESCE(SUM(o.total_value), 0) AS total_value,
                       MAX(o.order_date) AS last_order_date,
                       100.0 * COUNT(o.id) FILTER (WHERE s.last_ship <= o.delivery_date)
                           / NULLIF(COUNT(o.id) FILTER (WHERE s.last_ship IS NOT NULL AND o.delivery_date IS NOT NULL), 0) AS on_time_percent
                FROM orders o
                JOIN buyers b ON b.id = o.buyer_id
                LEFT JOIN (SELECT order_id, SUM(quantity) AS qty FROM order_items GROUP BY order_id) q ON q.order_id = o.id
                LEFT JOIN (SELECT order_id, MAX(COALESCE(shipment_date, etd)) AS last_ship FROM shipments GROUP BY order_id) s ON s.order_id = o.id
                WHERE o.organization_id = :orgId /*filters*/
                GROUP BY b.code, b.name, b.country, o.currency
                ORDER BY total_value DESC
                """.formatted(ACTIVE_ORDER_STATUSES);
        return new ReportDefinition("buyer-summary", "Buyer Order Summary", "Buyers",
                "Orders, quantity, value and on-time delivery % per buyer (Doc 14.1). Sort shows which buyers generate the most business.",
                List.of(from("Order date from"), to("Order date to"), buyer(), status("Order status", ORDER_STATUSES)),
                "ORDER_VIEW", false,
                List.of(text("buyer_code", "Buyer code"), text("buyer_name", "Buyer"), text("country", "Country"),
                        text("currency", "Currency"), number("orders", "Orders"), number("active_orders", "Active orders"),
                        number("total_qty", "Total qty (pcs)"), money("total_value", "Total value"),
                        date("last_order_date", "Last order"), pct("on_time_percent", "On-time delivery %")),
                p -> {
                    ReportSql q = orderFilters(new ReportSql(sql, p), p);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Buyers", rows.stream().map(r -> r.get("buyer_code")).distinct().count()));
                    summary.add(item("Orders", sumLong(rows, "orders")));
                    summary.add(item("Active orders", sumLong(rows, "active_orders")));
                    summary.add(item("Total quantity (pcs)", sumLong(rows, "total_qty")));
                    summary.addAll(sumByCurrency(rows, "Total order value", "total_value", "currency"));
                    summary.add(item("Average on-time delivery %", avg(rows, "on_time_percent")));
                    return new ReportData(rows, summary);
                });
    }

    // ------------------------------------------------------- 14.2 Merchandising

    private ReportDefinition inquiryPipeline() {
        String sql = """
                SELECT i.inquiry_no, b.name AS buyer_name, se.name AS season, u.full_name AS merchandiser, i.status,
                       i.target_quantity, i.target_price, i.target_currency AS currency,
                       i.target_quantity * i.target_price AS estimated_value,
                       i.delivery_requirement, i.created_at::date AS created_date,
                       CURRENT_DATE - i.created_at::date AS age_days
                FROM inquiries i
                JOIN buyers b ON b.id = i.buyer_id
                LEFT JOIN seasons se ON se.id = i.season_id
                LEFT JOIN users u ON u.id = i.merchandiser_id
                WHERE i.organization_id = :orgId /*filters*/
                ORDER BY i.created_at DESC
                """;
        List<String> statuses = List.of("OPEN", "QUOTED", "WON", "LOST", "HOLD");
        return new ReportDefinition("inquiry-pipeline", "Inquiry Pipeline", "Merchandising",
                "Every inquiry with status, target quantity/price and age; summary shows pipeline value and win rate (Doc 14.2).",
                List.of(from("Received from"), to("Received to"), buyer(), status("Inquiry status", statuses)),
                "INQUIRY_VIEW", false,
                List.of(text("inquiry_no", "Inquiry no"), text("buyer_name", "Buyer"), text("season", "Season"),
                        text("merchandiser", "Merchandiser"), text("status", "Status"),
                        number("target_quantity", "Target qty"), money("target_price", "Target price"),
                        text("currency", "Currency"), money("estimated_value", "Est. value"),
                        date("delivery_requirement", "Delivery req."), date("created_date", "Received"),
                        number("age_days", "Age (days)")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("i.created_at::date >= :from", "from", p.date("from"))
                            .and("i.created_at::date <= :to", "to", p.date("to"))
                            .and("i.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("i.status = :status", "status", p.text("status"))
                            .scope("i.buyer_id IN (:scopeBuyerIds)", null);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    long won = countEq(rows, "status", "WON");
                    long lost = countEq(rows, "status", "LOST");
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Total inquiries", rows.size()));
                    for (String s : statuses) {
                        summary.add(item(titleCase(s), countEq(rows, "status", s)));
                    }
                    summary.add(item("Win rate % (won / decided)", percent(won, won + lost)));
                    summary.addAll(sumByCurrency(rows.stream()
                                    .filter(r -> "OPEN".equals(r.get("status")) || "QUOTED".equals(r.get("status"))).toList(),
                            "Open pipeline value", "estimated_value", "currency"));
                    return new ReportData(rows, summary);
                });
    }

    private ReportDefinition costingMargin() {
        String sql = """
                SELECT st.style_no, b.name AS buyer_name, c.version_no, c.status, c.currency, c.quantity,
                       c.total_cost, c.target_price, c.margin_percent,
                       CASE WHEN c.margin_percent IS NOT NULL AND c.margin_percent < %d THEN 'Yes' ELSE 'No' END AS below_floor,
                       c.created_at::date AS created_date, c.approved_at::date AS approved_date
                FROM costings c
                JOIN styles st ON st.id = c.style_id
                JOIN buyers b ON b.id = st.buyer_id
                WHERE c.organization_id = :orgId /*filters*/
                ORDER BY c.created_at DESC
                """.formatted(MARGIN_FLOOR_PERCENT);
        return new ReportDefinition("costing-margin", "Costing Margin", "Merchandising",
                "Costing sheets with cost per unit, target price and margin %; flags margins under the " + MARGIN_FLOOR_PERCENT + "% floor (Doc 9.1).",
                List.of(from("Created from"), to("Created to"), buyer(), status("Costing status", List.of("DRAFT", "APPROVED", "SUPERSEDED"))),
                "COSTING_VIEW", true,
                List.of(text("style_no", "Style"), text("buyer_name", "Buyer"), number("version_no", "Version"),
                        text("status", "Status"), text("currency", "Currency"), number("quantity", "Qty"),
                        money("total_cost", "Cost / unit"), money("target_price", "Target price"),
                        pct("margin_percent", "Margin %"), text("below_floor", "Below floor"),
                        date("created_date", "Created"), date("approved_date", "Approved")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("c.created_at::date >= :from", "from", p.date("from"))
                            .and("c.created_at::date <= :to", "to", p.date("to"))
                            .and("st.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("c.status = :status", "status", p.text("status"))
                            .scope("st.buyer_id IN (:scopeBuyerIds)", null);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    return new ReportData(rows, List.of(
                            item("Costings", rows.size()),
                            item("Approved", countEq(rows, "status", "APPROVED")),
                            item("Draft", countEq(rows, "status", "DRAFT")),
                            item("Average margin %", avg(rows, "margin_percent")),
                            item("Below " + MARGIN_FLOOR_PERCENT + "% margin floor", countEq(rows, "below_floor", "Yes"))));
                });
    }

    private ReportDefinition sampleApproval() {
        String sql = """
                SELECT s.sample_no, st.style_no, b.name AS buyer_name, f.name AS factory_name, sty.name AS sample_type,
                       s.request_date, s.required_date, s.current_status AS status,
                       (SELECT COUNT(*) FROM sample_revisions r WHERE r.sample_id = s.id) AS revisions,
                       (SELECT MAX(r.submitted_date) FROM sample_revisions r WHERE r.sample_id = s.id) AS last_submitted,
                       CASE WHEN s.current_status <> 'APPROVED' AND s.required_date < CURRENT_DATE THEN 'Yes' ELSE 'No' END AS overdue,
                       CURRENT_DATE - s.request_date AS age_days
                FROM samples s
                JOIN styles st ON st.id = s.style_id
                JOIN buyers b ON b.id = s.buyer_id
                JOIN sample_types sty ON sty.id = s.sample_type_id
                LEFT JOIN factories f ON f.id = s.factory_id
                WHERE s.organization_id = :orgId /*filters*/
                ORDER BY s.request_date DESC
                """;
        List<String> statuses = List.of("REQUESTED", "SUBMITTED", "APPROVED", "REJECTED", "RETURNED");
        return new ReportDefinition("sample-approval", "Sample Approval Status", "Merchandising",
                "Samples by status with revision count and overdue flag; summary shows approval rate and pending buyer approvals (Doc 14.2).",
                List.of(from("Requested from"), to("Requested to"), buyer(), factory(), status("Sample status", statuses)),
                "SAMPLE_VIEW", false,
                List.of(text("sample_no", "Sample no"), text("style_no", "Style"), text("buyer_name", "Buyer"),
                        text("factory_name", "Factory"), text("sample_type", "Type"), date("request_date", "Requested"),
                        date("required_date", "Required by"), text("status", "Status"), number("revisions", "Revisions"),
                        date("last_submitted", "Last submitted"), text("overdue", "Overdue"), number("age_days", "Age (days)")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("s.request_date >= :from", "from", p.date("from"))
                            .and("s.request_date <= :to", "to", p.date("to"))
                            .and("s.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("s.factory_id = :factoryId", "factoryId", p.id("factoryId"))
                            .and("s.current_status = :status", "status", p.text("status"))
                            .scope("s.buyer_id IN (:scopeBuyerIds)", "s.factory_id IN (:scopeFactoryIds)");
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    ReportSql pending = new ReportSql("""
                            SELECT COUNT(*) FROM approvals a
                            JOIN sample_revisions r ON r.id = a.target_id
                            JOIN samples s ON s.id = r.sample_id
                            WHERE a.organization_id = :orgId AND s.organization_id = :orgId
                              AND a.target_type = 'SAMPLE_REVISION'
                              AND a.status IN ('SUBMITTED', 'PENDING', 'RESUBMITTED') /*filters*/
                            """, p)
                            .scope("s.buyer_id IN (:scopeBuyerIds)", "s.factory_id IN (:scopeFactoryIds)");
                    Long pendingApprovals = jdbc.queryForObject(pending.sql(), pending.params(), Long.class);
                    long approved = countEq(rows, "status", "APPROVED");
                    long rejected = countEq(rows, "status", "REJECTED");
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Samples", rows.size()));
                    for (String s : statuses) {
                        summary.add(item(titleCase(s), countEq(rows, "status", s)));
                    }
                    summary.add(item("Overdue", countEq(rows, "overdue", "Yes")));
                    summary.add(item("Approval rate % (approved / decided)", percent(approved, approved + rejected)));
                    summary.add(item("Average revisions per sample", avg(rows, "revisions")));
                    summary.add(item("Sample approvals awaiting decision", pendingApprovals));
                    return new ReportData(rows, summary);
                });
    }

    // ---------------------------------------------------------------- 14.3 Orders

    private ReportDefinition orderStatus() {
        String sql = """
                SELECT o.order_no, o.buyer_po_no, b.name AS buyer_name, %s AS factories, o.status,
                       o.order_date, o.ex_factory_date, o.delivery_date,
                       COALESCE((SELECT SUM(oi.quantity) FROM order_items oi WHERE oi.order_id = o.id), 0) AS quantity,
                       o.total_value, o.currency,
                       o.delivery_date - CURRENT_DATE AS days_to_delivery
                FROM orders o
                JOIN buyers b ON b.id = o.buyer_id
                WHERE o.organization_id = :orgId /*filters*/
                ORDER BY o.delivery_date NULLS LAST, o.order_no
                """.formatted(ORDER_FACTORIES);
        return new ReportDefinition("order-status", "Order Book & Status", "Orders",
                "All orders with buyer, factories, quantity, value and days to delivery; summary breaks down by status (Doc 14.3).",
                List.of(from("Order date from"), to("Order date to"), buyer(), factory(), status("Order status", ORDER_STATUSES)),
                "ORDER_VIEW", false,
                List.of(text("order_no", "Order no"), text("buyer_po_no", "Buyer PO"), text("buyer_name", "Buyer"),
                        text("factories", "Factories"), text("status", "Status"), date("order_date", "Order date"),
                        date("ex_factory_date", "Ex-factory"), date("delivery_date", "Delivery"),
                        number("quantity", "Qty (pcs)"), money("total_value", "Value"), text("currency", "Currency"),
                        number("days_to_delivery", "Days to delivery")),
                p -> {
                    ReportSql q = orderFilters(new ReportSql(sql, p), p);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Orders", rows.size()));
                    for (String s : ORDER_STATUSES) {
                        summary.add(item(titleCase(s), countEq(rows, "status", s)));
                    }
                    summary.add(item("Late (delivery date passed, not shipped)", count(rows, r ->
                            List.of("CONFIRMED", "IN_PROGRESS", "PARTIALLY_SHIPPED").contains(r.get("status"))
                                    && r.get("days_to_delivery") instanceof Number n && n.longValue() < 0)));
                    summary.add(item("Total quantity (pcs)", sumLong(rows, "quantity")));
                    summary.addAll(sumByCurrency(rows, "Total order value", "total_value", "currency"));
                    return new ReportData(rows, summary);
                });
    }

    private ReportDefinition orderDelay() {
        String effective = "COALESCE(m.revised_date, m.planned_date)";
        String sql = """
                SELECT o.order_no, b.name AS buyer_name, mt.name AS milestone, f.name AS factory_name,
                       u.full_name AS responsible, m.planned_date, m.revised_date,
                       CURRENT_DATE - %1$s AS delay_days,
                       CASE WHEN CURRENT_DATE - %1$s > %2$d THEN 'CRITICAL_DELAY' ELSE 'OVERDUE' END AS status,
                       m.delay_reason
                FROM ta_milestones m
                JOIN orders o ON o.id = m.order_id
                JOIN buyers b ON b.id = o.buyer_id
                JOIN milestone_types mt ON mt.id = m.milestone_type_id
                LEFT JOIN factories f ON f.id = m.responsible_factory_id
                LEFT JOIN users u ON u.id = m.responsible_user_id
                WHERE o.organization_id = :orgId
                  AND m.actual_date IS NULL AND %1$s < CURRENT_DATE
                  AND o.status NOT IN ('CANCELLED', 'CLOSED', 'SHIPPED') /*filters*/
                ORDER BY delay_days DESC, o.order_no
                """.formatted(effective, CRITICAL_DELAY_DAYS);
        return new ReportDefinition("order-delay", "Delayed Orders (T&A)", "T&A",
                "Open T&A milestones past their planned/revised date, with delay days and critical-delay flag (Doc 14.4 / 9.5).",
                List.of(from("Due from"), to("Due to"), buyer(), factory(), status("Delay status", List.of("OVERDUE", "CRITICAL_DELAY"))),
                "TA_VIEW", false,
                List.of(text("order_no", "Order no"), text("buyer_name", "Buyer"), text("milestone", "Milestone"),
                        text("factory_name", "Responsible factory"), text("responsible", "Responsible person"),
                        date("planned_date", "Planned"), date("revised_date", "Revised"), number("delay_days", "Delay (days)"),
                        text("status", "Status"), text("delay_reason", "Delay reason")),
                p -> {
                    String status = p.text("status");
                    ReportSql q = new ReportSql(sql, p)
                            .and(effective + " >= :from", "from", p.date("from"))
                            .and(effective + " <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("(m.responsible_factory_id = :factoryId OR " + ORDER_HAS_FACTORY + ")", "factoryId", p.id("factoryId"))
                            .andIf("CRITICAL_DELAY".equals(status), "CURRENT_DATE - " + effective + " > " + CRITICAL_DELAY_DAYS)
                            .andIf("OVERDUE".equals(status), "CURRENT_DATE - " + effective + " <= " + CRITICAL_DELAY_DAYS)
                            .scope(ORDER_SCOPE_BUYER, "(m.responsible_factory_id IN (:scopeFactoryIds) OR " + ORDER_SCOPE_FACTORY + ")");
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    return new ReportData(rows, List.of(
                            item("Delayed milestones", rows.size()),
                            item("Critical delays (> " + CRITICAL_DELAY_DAYS + " days)", countEq(rows, "status", "CRITICAL_DELAY")),
                            item("Orders affected", rows.stream().map(r -> r.get("order_no")).distinct().count()),
                            item("Average delay (days)", avg(rows, "delay_days")),
                            item("Longest delay (days)", rows.stream().map(r -> toDecimal(r.get("delay_days")))
                                    .filter(java.util.Objects::nonNull).mapToLong(java.math.BigDecimal::longValue).max().orElse(0))));
                });
    }

    // ------------------------------------------------------------ 14.4 Production

    private ReportDefinition productionProgress() {
        String sql = """
                SELECT o.order_no, b.name AS buyer_name, %s AS factories, o.status, o.ex_factory_date,
                       COALESCE(q.qty, 0) AS order_qty,
                       COALESCE(pu.cut, 0) AS cutting_qty, COALESCE(pu.sewn, 0) AS sewing_qty,
                       COALESCE(pu.finished, 0) AS finishing_qty, COALESCE(pu.packed, 0) AS packing_qty,
                       COALESCE(pu.rejected, 0) AS rejection_qty,
                       CASE WHEN q.qty > 0 THEN 100.0 * COALESCE(pu.packed, 0) / q.qty END AS progress_percent,
                       pu.last_update
                FROM orders o
                JOIN buyers b ON b.id = o.buyer_id
                LEFT JOIN (SELECT order_id, SUM(quantity) AS qty FROM order_items GROUP BY order_id) q ON q.order_id = o.id
                LEFT JOIN (SELECT order_id, SUM(cutting_qty) AS cut, SUM(sewing_qty) AS sewn, SUM(finishing_qty) AS finished,
                                  SUM(packing_qty) AS packed, SUM(rejection_qty) AS rejected, MAX(update_date) AS last_update
                           FROM production_updates GROUP BY order_id) pu ON pu.order_id = o.id
                WHERE o.organization_id = :orgId AND o.status <> 'CANCELLED' /*filters*/
                ORDER BY o.ex_factory_date NULLS LAST, o.order_no
                """.formatted(ORDER_FACTORIES);
        return new ReportDefinition("production-progress", "Production Progress", "Production",
                "Cumulative cutting/sewing/finishing/packing per order and % packed against order quantity (Doc 14.4 / 9.6).",
                List.of(from("Order date from"), to("Order date to"), buyer(), factory(), status("Order status", ORDER_STATUSES)),
                "PRODUCTION_VIEW", false,
                List.of(text("order_no", "Order no"), text("buyer_name", "Buyer"), text("factories", "Factories"),
                        text("status", "Status"), date("ex_factory_date", "Ex-factory"), number("order_qty", "Order qty"),
                        number("cutting_qty", "Cut"), number("sewing_qty", "Sewn"), number("finishing_qty", "Finished"),
                        number("packing_qty", "Packed"), number("rejection_qty", "Rejected"),
                        pct("progress_percent", "Progress %"), date("last_update", "Last update")),
                p -> {
                    ReportSql q = orderFilters(new ReportSql(sql, p), p);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    long orderQty = sumLong(rows, "order_qty");
                    long packed = sumLong(rows, "packing_qty");
                    long cut = sumLong(rows, "cutting_qty");
                    return new ReportData(rows, List.of(
                            item("Orders", rows.size()),
                            item("Total order quantity (pcs)", orderQty),
                            item("Total packed (pcs)", packed),
                            item("Overall progress %", percent(packed, orderQty)),
                            item("Rejection rate % (of cut)", percent(sumLong(rows, "rejection_qty"), cut)),
                            item("Orders not started", count(rows, r -> r.get("last_update") == null))));
                });
    }

    private ReportDefinition factoryPerformance() {
        String sql = """
                WITH ofac AS (
                    SELECT DISTINCT oi.order_id, oi.factory_id
                    FROM order_items oi JOIN orders o ON o.id = oi.order_id
                    WHERE o.organization_id = :orgId AND o.status <> 'CANCELLED' /*filters*/
                ), ms AS (
                    SELECT ofac.factory_id, COUNT(*) AS milestones,
                           COUNT(*) FILTER (WHERE m.actual_date IS NOT NULL) AS completed,
                           COUNT(*) FILTER (WHERE m.actual_date IS NOT NULL AND m.actual_date <= COALESCE(m.revised_date, m.planned_date)) AS on_time,
                           COUNT(*) FILTER (WHERE m.actual_date IS NULL AND COALESCE(m.revised_date, m.planned_date) < CURRENT_DATE) AS overdue
                    FROM ta_milestones m JOIN ofac ON ofac.order_id = m.order_id
                    GROUP BY ofac.factory_id
                ), qa AS (
                    SELECT ofac.factory_id, COUNT(*) AS inspections, COUNT(*) FILTER (WHERE ins.result = 'FAIL') AS failed
                    FROM inspections ins JOIN ofac ON ofac.order_id = ins.order_id
                    GROUP BY ofac.factory_id
                )
                SELECT f.code AS factory_code, f.name AS factory_name,
                       (SELECT COUNT(DISTINCT x.order_id) FROM ofac x WHERE x.factory_id = f.id) AS orders,
                       COALESCE(ms.milestones, 0) AS milestones, COALESCE(ms.completed, 0) AS completed,
                       COALESCE(ms.on_time, 0) AS on_time, COALESCE(ms.overdue, 0) AS overdue,
                       100.0 * ms.on_time / NULLIF(ms.completed, 0) AS on_time_percent,
                       COALESCE(qa.inspections, 0) AS inspections,
                       100.0 * qa.failed / NULLIF(qa.inspections, 0) AS fail_rate_percent
                FROM factories f
                JOIN (SELECT DISTINCT factory_id FROM ofac) ff ON ff.factory_id = f.id
                LEFT JOIN ms ON ms.factory_id = f.id
                LEFT JOIN qa ON qa.factory_id = f.id
                WHERE f.organization_id = :orgId
                ORDER BY on_time_percent NULLS LAST, f.name
                """;
        return new ReportDefinition("factory-performance", "Factory Performance", "Production",
                "On-time T&A milestone completion % and inspection fail rate per factory — shows which factories are behind (Doc 14.4 / 14.5).",
                List.of(from("Order date from"), to("Order date to"), buyer(), factory()),
                "TA_VIEW", false,
                List.of(text("factory_code", "Code"), text("factory_name", "Factory"), number("orders", "Orders"),
                        number("milestones", "Milestones"), number("completed", "Completed"), number("on_time", "On time"),
                        number("overdue", "Overdue"), pct("on_time_percent", "On-time %"),
                        number("inspections", "Inspections"), pct("fail_rate_percent", "Fail rate %")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("o.order_date >= :from", "from", p.date("from"))
                            .and("o.order_date <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("oi.factory_id = :factoryId", "factoryId", p.id("factoryId"))
                            .scope(ORDER_SCOPE_BUYER, "oi.factory_id IN (:scopeFactoryIds)");
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    return new ReportData(rows, List.of(
                            item("Factories", rows.size()),
                            item("Overall on-time %", percent(sumLong(rows, "on_time"), sumLong(rows, "completed"))),
                            item("Overdue milestones", sumLong(rows, "overdue")),
                            item("Average fail rate %", avg(rows, "fail_rate_percent"))));
                });
    }

    // --------------------------------------------------------------- 14.5 Quality

    private ReportDefinition qualityInspections() {
        String sql = """
                SELECT ins.inspection_date, o.order_no, b.name AS buyer_name, %s AS factories, ins.inspection_type,
                       ins.inspected_qty, ins.aql_level, ins.result,
                       COALESCE(dq.defect_qty, 0) AS defect_qty,
                       CASE WHEN ins.inspected_qty > 0 THEN 100.0 * COALESCE(dq.defect_qty, 0) / ins.inspected_qty END AS defect_rate,
                       u.full_name AS inspector
                FROM inspections ins
                JOIN orders o ON o.id = ins.order_id
                JOIN buyers b ON b.id = o.buyer_id
                LEFT JOIN (SELECT inspection_id, SUM(quantity) AS defect_qty FROM defects GROUP BY inspection_id) dq ON dq.inspection_id = ins.id
                LEFT JOIN users u ON u.id = ins.inspector_id
                WHERE o.organization_id = :orgId /*filters*/
                ORDER BY ins.inspection_date DESC, o.order_no
                """.formatted(ORDER_FACTORIES);
        return new ReportDefinition("quality-inspections", "Inspection Results", "Quality",
                "Inline/midline/final inspections with result and defect rate; summary shows pass rate (Doc 14.5).",
                List.of(from("Inspected from"), to("Inspected to"), buyer(), factory(),
                        status("Result", List.of("PASS", "FAIL", "REINSPECT")),
                        new ReportFilterResponse("inspectionType", "Inspection type", "status", false, List.of("INLINE", "MIDLINE", "FINAL"))),
                "QUALITY_VIEW", false,
                List.of(date("inspection_date", "Date"), text("order_no", "Order no"), text("buyer_name", "Buyer"),
                        text("factories", "Factories"), text("inspection_type", "Type"), number("inspected_qty", "Inspected qty"),
                        text("aql_level", "AQL"), text("result", "Result"), number("defect_qty", "Defects"),
                        pct("defect_rate", "Defect rate %"), text("inspector", "Inspector")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("ins.inspection_date >= :from", "from", p.date("from"))
                            .and("ins.inspection_date <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and(ORDER_HAS_FACTORY, "factoryId", p.id("factoryId"))
                            .and("ins.result = :status", "status", p.text("status"))
                            .and("ins.inspection_type = :inspectionType", "inspectionType", p.text("inspectionType"))
                            .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    long pass = countEq(rows, "result", "PASS");
                    long fail = countEq(rows, "result", "FAIL");
                    return new ReportData(rows, List.of(
                            item("Inspections", rows.size()),
                            item("Passed", pass),
                            item("Failed", fail),
                            item("Re-inspect", countEq(rows, "result", "REINSPECT")),
                            item("Pass rate %", percent(pass, rows.size())),
                            item("Total inspected (pcs)", sumLong(rows, "inspected_qty")),
                            item("Total defects (pcs)", sumLong(rows, "defect_qty"))));
                });
    }

    private ReportDefinition defectAnalysis() {
        String sql = """
                SELECT dt.category, dt.name AS defect, d.severity,
                       COUNT(*) AS occurrences, SUM(d.quantity) AS defect_qty,
                       COUNT(DISTINCT d.inspection_id) AS inspections, COUNT(DISTINCT ins.order_id) AS orders
                FROM defects d
                JOIN defect_types dt ON dt.id = d.defect_type_id
                JOIN inspections ins ON ins.id = d.inspection_id
                JOIN orders o ON o.id = ins.order_id
                WHERE o.organization_id = :orgId /*filters*/
                GROUP BY dt.category, dt.name, d.severity
                ORDER BY defect_qty DESC
                """;
        return new ReportDefinition("defect-analysis", "Defect Analysis", "Quality",
                "Defect quantity by category, defect type and severity with share of total, plus open CAPA count (Doc 14.5).",
                List.of(from("Inspected from"), to("Inspected to"), buyer(), factory(),
                        status("Severity", List.of("MINOR", "MAJOR", "CRITICAL"))),
                "QUALITY_VIEW", false,
                List.of(text("category", "Category"), text("defect", "Defect"), text("severity", "Severity"),
                        number("occurrences", "Occurrences"), number("defect_qty", "Defect qty"),
                        pct("share_percent", "Share %"), number("inspections", "Inspections"), number("orders", "Orders")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("ins.inspection_date >= :from", "from", p.date("from"))
                            .and("ins.inspection_date <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and(ORDER_HAS_FACTORY, "factoryId", p.id("factoryId"))
                            .and("d.severity = :status", "status", p.text("status"))
                            .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    long total = sumLong(rows, "defect_qty");
                    for (Map<String, Object> row : rows) {
                        row.put("share_percent", percent(toDecimal(row.get("defect_qty")).longValue(), total));
                    }
                    Map<String, Long> byCategory = new LinkedHashMap<>();
                    rows.forEach(r -> byCategory.merge(String.valueOf(r.get("category")), toDecimal(r.get("defect_qty")).longValue(), Long::sum));
                    String topCategory = byCategory.entrySet().stream().max(Map.Entry.comparingByValue())
                            .map(Map.Entry::getKey).orElse("-");
                    ReportSql capaSql = new ReportSql("""
                            SELECT COUNT(*) FILTER (WHERE c.status <> 'CLOSED') AS open_capa,
                                   AVG(EXTRACT(EPOCH FROM (c.closed_at - c.created_at)) / 86400) FILTER (WHERE c.closed_at IS NOT NULL) AS avg_close_days
                            FROM capa_records c
                            LEFT JOIN defects d ON d.id = c.defect_id
                            JOIN inspections ins ON ins.id = COALESCE(c.inspection_id, d.inspection_id)
                            JOIN orders o ON o.id = ins.order_id
                            WHERE o.organization_id = :orgId /*filters*/
                            """, p)
                            .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
                    Map<String, Object> capa = jdbc.queryForMap(capaSql.sql(), capaSql.params());
                    BigDecimal avgClose = toDecimal(capa.get("avg_close_days"));
                    return new ReportData(rows, List.of(
                            item("Total defects (pcs)", total),
                            item("Critical", sumLong(rows.stream().filter(r -> "CRITICAL".equals(r.get("severity"))).toList(), "defect_qty")),
                            item("Major", sumLong(rows.stream().filter(r -> "MAJOR".equals(r.get("severity"))).toList(), "defect_qty")),
                            item("Minor", sumLong(rows.stream().filter(r -> "MINOR".equals(r.get("severity"))).toList(), "defect_qty")),
                            item("Top defect category", topCategory),
                            item("Open CAPA records", capa.get("open_capa")),
                            item("Average CAPA closure (days)", avgClose == null ? null : avgClose.setScale(1, java.math.RoundingMode.HALF_UP))));
                });
    }

    // -------------------------------------------------------------- 14.6 Shipment

    private ReportDefinition shipmentStatus() {
        String sql = """
                SELECT sh.shipment_no, o.order_no, b.name AS buyer_name, sh.status, sh.etd, sh.eta, sh.shipment_date,
                       sh.quantity_shipped, sh.cartons, sh.port_of_loading, sh.port_of_discharge,
                       CASE WHEN sh.is_partial THEN 'Yes' ELSE 'No' END AS partial,
                       CASE WHEN sh.status = 'DELAYED' OR (sh.status = 'BOOKED' AND sh.etd < CURRENT_DATE) THEN 'Yes' ELSE 'No' END AS at_risk
                FROM shipments sh
                JOIN orders o ON o.id = sh.order_id
                JOIN buyers b ON b.id = o.buyer_id
                WHERE sh.organization_id = :orgId AND o.organization_id = :orgId /*filters*/
                ORDER BY sh.etd DESC NULLS LAST, sh.shipment_no
                """;
        List<String> statuses = List.of("BOOKED", "IN_TRANSIT", "DELIVERED", "DELAYED");
        return new ReportDefinition("shipment-status", "Shipment Status", "Shipment",
                "Shipments with ETD/ETA, quantity, ports and an at-risk flag (delayed, or ETD passed while still booked) (Doc 14.6).",
                List.of(from("ETD from"), to("ETD to"), buyer(), factory(), status("Shipment status", statuses)),
                "SHIPMENT_VIEW", false,
                List.of(text("shipment_no", "Shipment no"), text("order_no", "Order no"), text("buyer_name", "Buyer"),
                        text("status", "Status"), date("etd", "ETD"), date("eta", "ETA"), date("shipment_date", "Shipped on"),
                        number("quantity_shipped", "Qty shipped"), number("cartons", "Cartons"),
                        text("port_of_loading", "Port of loading"), text("port_of_discharge", "Port of discharge"),
                        text("partial", "Partial"), text("at_risk", "At risk")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("sh.etd >= :from", "from", p.date("from"))
                            .and("sh.etd <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and(ORDER_HAS_FACTORY, "factoryId", p.id("factoryId"))
                            .and("sh.status = :status", "status", p.text("status"))
                            .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Shipments", rows.size()));
                    for (String s : statuses) {
                        summary.add(item(titleCase(s), countEq(rows, "status", s)));
                    }
                    summary.add(item("At risk", countEq(rows, "at_risk", "Yes")));
                    summary.add(item("Partial shipments", countEq(rows, "partial", "Yes")));
                    summary.add(item("Total quantity shipped (pcs)", sumLong(rows, "quantity_shipped")));
                    summary.add(item("Total cartons", sumLong(rows, "cartons")));
                    return new ReportData(rows, summary);
                });
    }

    private ReportDefinition documentExpiry() {
        String state = """
                CASE WHEN x.expiry_date < CURRENT_DATE THEN 'EXPIRED'
                     WHEN x.expiry_date <= CURRENT_DATE + %d THEN 'EXPIRING_SOON'
                     ELSE 'VALID' END""".formatted(EXPIRY_WARNING_DAYS);
        String sql = """
                SELECT x.document, x.category, x.entity_type, x.reference, x.version_no, x.document_status,
                       x.expiry_date, x.expiry_date - CURRENT_DATE AS days_to_expiry, %s AS expiry_state
                FROM (
                    SELECT dt.name AS document, dt.category, d.entity_type,
                           CASE d.entity_type
                               WHEN 'ORDER' THEN (SELECT o.order_no FROM orders o WHERE o.id = d.entity_id AND o.organization_id = :orgId)
                               WHEN 'SHIPMENT' THEN (SELECT s.shipment_no FROM shipments s WHERE s.id = d.entity_id AND s.organization_id = :orgId)
                               WHEN 'FACTORY' THEN (SELECT f.name FROM factories f WHERE f.id = d.entity_id AND f.organization_id = :orgId)
                               WHEN 'STYLE' THEN (SELECT st.style_no FROM styles st WHERE st.id = d.entity_id AND st.organization_id = :orgId)
                           END AS reference,
                           d.version_no, d.status AS document_status, d.expiry_date,
                           CASE d.entity_type
                               WHEN 'ORDER' THEN d.entity_id
                               WHEN 'SHIPMENT' THEN (SELECT s.order_id FROM shipments s WHERE s.id = d.entity_id AND s.organization_id = :orgId)
                           END AS scope_order_id,
                           CASE d.entity_type
                               WHEN 'ORDER' THEN (SELECT o.buyer_id FROM orders o WHERE o.id = d.entity_id AND o.organization_id = :orgId)
                               WHEN 'SHIPMENT' THEN (SELECT o.buyer_id FROM shipments s JOIN orders o ON o.id = s.order_id
                                                     WHERE s.id = d.entity_id AND s.organization_id = :orgId)
                               WHEN 'STYLE' THEN (SELECT st.buyer_id FROM styles st WHERE st.id = d.entity_id AND st.organization_id = :orgId)
                           END AS scope_buyer_id,
                           CASE WHEN d.entity_type = 'FACTORY' THEN d.entity_id END AS scope_factory_id
                    FROM documents d JOIN document_types dt ON dt.id = d.document_type_id
                    WHERE d.organization_id = :orgId AND d.expiry_date IS NOT NULL
                    UNION ALL
                    SELECT fc.cert_name, 'CERTIFICATION', 'FACTORY', f.name, NULL::int, 'CERTIFICATE', fc.expiry_date,
                           NULL::bigint, NULL::bigint, fc.factory_id
                    FROM factory_certifications fc JOIN factories f ON f.id = fc.factory_id
                    WHERE f.organization_id = :orgId AND fc.expiry_date IS NOT NULL
                ) x
                WHERE 1 = 1 /*filters*/
                ORDER BY x.expiry_date
                """.formatted(state);
        return new ReportDefinition("document-expiry", "Document & Certificate Expiry", "Documents",
                "Commercial/compliance documents and factory certifications with expiry dates; flags expired and expiring within " + EXPIRY_WARNING_DAYS + " days.",
                List.of(from("Expires from"), to("Expires to"), status("Expiry state", List.of("EXPIRED", "EXPIRING_SOON", "VALID"))),
                "DOCUMENT_VIEW", false,
                List.of(text("document", "Document"), text("category", "Category"), text("entity_type", "Linked to"),
                        text("reference", "Reference"), number("version_no", "Version"), text("document_status", "Doc status"),
                        date("expiry_date", "Expiry date"), number("days_to_expiry", "Days to expiry"), text("expiry_state", "State")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("x.expiry_date >= :from", "from", p.date("from"))
                            .and("x.expiry_date <= :to", "to", p.date("to"))
                            .and(state + " = :status", "status", p.text("status"))
                            .scope("x.scope_buyer_id IN (:scopeBuyerIds)",
                                    "(x.scope_factory_id IN (:scopeFactoryIds) OR EXISTS (SELECT 1 FROM order_items osf"
                                            + " WHERE osf.order_id = x.scope_order_id AND osf.factory_id IN (:scopeFactoryIds)))");
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    return new ReportData(rows, List.of(
                            item("Documents tracked", rows.size()),
                            item("Expired", countEq(rows, "expiry_state", "EXPIRED")),
                            item("Expiring within " + EXPIRY_WARNING_DAYS + " days", countEq(rows, "expiry_state", "EXPIRING_SOON")),
                            item("Valid", countEq(rows, "expiry_state", "VALID"))));
                });
    }

    // ------------------------------------------------------------- 14.7 Financial

    private ReportDefinition receivablesPayables() {
        String sql = """
                SELECT x.kind, x.order_no, x.party, x.currency, x.amount, x.settled, x.outstanding, x.due_date,
                       CASE WHEN x.outstanding > 0 AND x.due_date < CURRENT_DATE THEN CURRENT_DATE - x.due_date ELSE 0 END AS days_overdue,
                       CASE WHEN x.outstanding <= 0 THEN 'Settled'
                            WHEN x.due_date >= CURRENT_DATE THEN 'Current'
                            WHEN CURRENT_DATE - x.due_date <= 30 THEN '1-30 days'
                            WHEN CURRENT_DATE - x.due_date <= 60 THEN '31-60 days'
                            WHEN CURRENT_DATE - x.due_date <= 90 THEN '61-90 days'
                            ELSE '90+ days' END AS aging_bucket
                FROM (
                    SELECT 'RECEIVABLE' AS kind, o.order_no, b.name AS party, r.currency, r.amount,
                           r.received_amount AS settled, r.amount - r.received_amount AS outstanding, r.due_date,
                           o.buyer_id, NULL::bigint AS factory_id
                    FROM receivables r JOIN orders o ON o.id = r.order_id JOIN buyers b ON b.id = r.buyer_id
                    WHERE o.organization_id = :orgId
                    UNION ALL
                    SELECT 'PAYABLE', o.order_no, f.name, p.currency, p.amount,
                           p.paid_amount, p.amount - p.paid_amount, p.due_date,
                           o.buyer_id, p.factory_id
                    FROM payables p JOIN orders o ON o.id = p.order_id JOIN factories f ON f.id = p.factory_id
                    WHERE o.organization_id = :orgId
                ) x
                WHERE 1 = 1 /*filters*/
                ORDER BY x.kind DESC, days_overdue DESC, x.due_date
                """;
        return new ReportDefinition("receivables-payables", "Receivables & Payables Aging", "Finance",
                "Buyer receivables and factory payables with outstanding balance and aging buckets (current/30/60/90+) (Doc 14.7).",
                List.of(from("Due from"), to("Due to"), buyer(), factory(),
                        new ReportFilterResponse("kind", "Type", "status", false, List.of("RECEIVABLE", "PAYABLE"))),
                "FINANCIAL_VIEW", true,
                List.of(text("kind", "Type"), text("order_no", "Order no"), text("party", "Buyer / factory"),
                        text("currency", "Currency"), money("amount", "Amount"), money("settled", "Received / paid"),
                        money("outstanding", "Outstanding"), date("due_date", "Due date"),
                        number("days_overdue", "Days overdue"), text("aging_bucket", "Aging")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("x.due_date >= :from", "from", p.date("from"))
                            .and("x.due_date <= :to", "to", p.date("to"))
                            .and("x.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("x.factory_id = :factoryId", "factoryId", p.id("factoryId"))
                            .and("x.kind = :kind", "kind", p.text("kind"))
                            .scope("x.buyer_id IN (:scopeBuyerIds)", "x.factory_id IN (:scopeFactoryIds)");
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<Map<String, Object>> receivables = rows.stream().filter(r -> "RECEIVABLE".equals(r.get("kind"))).toList();
                    List<Map<String, Object>> payables = rows.stream().filter(r -> "PAYABLE".equals(r.get("kind"))).toList();
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.addAll(sumByCurrency(receivables, "Receivable outstanding", "outstanding", "currency"));
                    summary.addAll(sumByCurrency(payables, "Payable outstanding", "outstanding", "currency"));
                    summary.add(item("Overdue receivables", count(receivables, r -> toDecimal(r.get("days_overdue")).signum() > 0)));
                    summary.add(item("Overdue payables", count(payables, r -> toDecimal(r.get("days_overdue")).signum() > 0)));
                    summary.add(item("Items 90+ days overdue", countEq(rows, "aging_bucket", "90+ days")));
                    return new ReportData(rows, summary);
                });
    }

    private ReportDefinition orderProfitability() {
        String sql = """
                SELECT o.order_no, b.name AS buyer_name, o.status, o.currency, COALESCE(q.qty, 0) AS quantity,
                       f.quoted_unit_price, f.actual_cost_unit, f.realized_unit_price,
                       CASE WHEN f.realized_unit_price IS NOT NULL THEN 'Realized' ELSE 'Quoted' END AS margin_basis,
                       CASE WHEN bp.price > 0 AND f.actual_cost_unit IS NOT NULL
                            THEN (bp.price - f.actual_cost_unit) / bp.price * 100 END AS margin_percent,
                       CASE WHEN f.actual_cost_unit IS NOT NULL THEN (bp.price - f.actual_cost_unit) * COALESCE(q.qty, 0) END AS margin_amount
                FROM order_financials f
                JOIN orders o ON o.id = f.order_id
                JOIN buyers b ON b.id = o.buyer_id
                CROSS JOIN LATERAL (SELECT COALESCE(f.realized_unit_price, f.quoted_unit_price) AS price) bp
                LEFT JOIN (SELECT order_id, SUM(quantity) AS qty FROM order_items GROUP BY order_id) q ON q.order_id = o.id
                WHERE o.organization_id = :orgId /*filters*/
                ORDER BY margin_percent NULLS LAST
                """;
        return new ReportDefinition("order-profitability", "Order Profitability", "Finance",
                "Per-order operational margin (realized price when known, else quoted) and margin amount; flags orders under the "
                        + MARGIN_FLOOR_PERCENT + "% floor (Doc 14.3 / 14.7).",
                List.of(from("Order date from"), to("Order date to"), buyer(), factory(), status("Order status", ORDER_STATUSES)),
                "FINANCIAL_VIEW", true,
                List.of(text("order_no", "Order no"), text("buyer_name", "Buyer"), text("status", "Status"),
                        text("currency", "Currency"), number("quantity", "Qty (pcs)"),
                        money("quoted_unit_price", "Quoted / unit"), money("actual_cost_unit", "Cost / unit"),
                        money("realized_unit_price", "Realized / unit"), text("margin_basis", "Basis"),
                        pct("margin_percent", "Margin %"), money("margin_amount", "Margin amount")),
                p -> {
                    ReportSql q = orderFilters(new ReportSql(sql, p), p);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Orders", rows.size()));
                    summary.add(item("Average margin %", avg(rows, "margin_percent")));
                    summary.add(item("Below " + MARGIN_FLOOR_PERCENT + "% margin floor", count(rows, r -> {
                        BigDecimal m = toDecimal(r.get("margin_percent"));
                        return m != null && m.compareTo(BigDecimal.valueOf(MARGIN_FLOOR_PERCENT)) < 0;
                    })));
                    summary.add(item("Loss-making orders", count(rows, r -> {
                        BigDecimal m = toDecimal(r.get("margin_percent"));
                        return m != null && m.signum() < 0;
                    })));
                    summary.addAll(sumByCurrency(rows, "Total margin", "margin_amount", "currency"));
                    return new ReportData(rows, summary);
                });
    }

    // ----------------------------------------------------------------- Claims

    private ReportDefinition claimsSummary() {
        String sql = """
                SELECT c.created_at::date AS raised_date, o.order_no, b.name AS buyer_name, sh.shipment_no,
                       c.raised_by, c.claim_type, c.status, c.claimed_amount, o.currency,
                       c.resolved_at::date AS resolved_date,
                       COALESCE(c.resolved_at::date, CURRENT_DATE) - c.created_at::date AS days_open,
                       c.description
                FROM claims c
                JOIN orders o ON o.id = c.order_id
                JOIN buyers b ON b.id = o.buyer_id
                LEFT JOIN shipments sh ON sh.id = c.shipment_id
                WHERE o.organization_id = :orgId /*filters*/
                ORDER BY c.created_at DESC
                """;
        List<String> statuses = List.of("OPEN", "UNDER_REVIEW", "RESOLVED", "REJECTED");
        return new ReportDefinition("claims-summary", "Claims Summary", "Claims",
                "Buyer and internal claims by type and status with claimed amount and days open (Doc 9.11).",
                List.of(from("Raised from"), to("Raised to"), buyer(), status("Claim status", statuses),
                        new ReportFilterResponse("claimType", "Claim type", "status", false,
                                List.of("SHORT_SHIPMENT", "QUALITY", "DELAY", "OTHER"))),
                "CLAIM_VIEW", false,
                List.of(date("raised_date", "Raised"), text("order_no", "Order no"), text("buyer_name", "Buyer"),
                        text("shipment_no", "Shipment"), text("raised_by", "Raised by"), text("claim_type", "Type"),
                        text("status", "Status"), money("claimed_amount", "Claimed amount"), text("currency", "Currency"),
                        date("resolved_date", "Resolved"), number("days_open", "Days open"), text("description", "Description")),
                p -> {
                    ReportSql q = new ReportSql(sql, p)
                            .and("c.created_at::date >= :from", "from", p.date("from"))
                            .and("c.created_at::date <= :to", "to", p.date("to"))
                            .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                            .and("c.status = :status", "status", p.text("status"))
                            .and("c.claim_type = :claimType", "claimType", p.text("claimType"))
                            .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
                    List<Map<String, Object>> rows = jdbc.queryForList(q.sql(), q.params());
                    List<ReportSummaryItem> summary = new ArrayList<>();
                    summary.add(item("Claims", rows.size()));
                    for (String s : statuses) {
                        summary.add(item(titleCase(s), countEq(rows, "status", s)));
                    }
                    summary.addAll(sumByCurrency(rows, "Total claimed", "claimed_amount", "currency"));
                    summary.add(item("Average resolution (days)", avg(rows.stream().filter(r -> r.get("resolved_date") != null).toList(), "days_open")));
                    return new ReportData(rows, summary);
                });
    }

    // ----------------------------------------------------------------- helpers

    /** Common order-level filters: order date range, buyer, factory (via order lines), order status, plus object-level scope. */
    private static ReportSql orderFilters(ReportSql q, ReportParams p) {
        return q.and("o.order_date >= :from", "from", p.date("from"))
                .and("o.order_date <= :to", "to", p.date("to"))
                .and("o.buyer_id = :buyerId", "buyerId", p.id("buyerId"))
                .and(ORDER_HAS_FACTORY, "factoryId", p.id("factoryId"))
                .and("o.status = :status", "status", p.text("status"))
                .scope(ORDER_SCOPE_BUYER, ORDER_SCOPE_FACTORY);
    }

    private static String titleCase(String status) {
        String lower = status.replace('_', ' ').toLowerCase();
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }

    private static ReportFilterResponse from(String label) {
        return new ReportFilterResponse("from", label, "date", false, null);
    }

    private static ReportFilterResponse to(String label) {
        return new ReportFilterResponse("to", label, "date", false, null);
    }

    private static ReportFilterResponse buyer() {
        return new ReportFilterResponse("buyerId", "Buyer", "buyer", false, null);
    }

    private static ReportFilterResponse factory() {
        return new ReportFilterResponse("factoryId", "Factory", "factory", false, null);
    }

    private static ReportFilterResponse status(String label, List<String> options) {
        return new ReportFilterResponse("status", label, "status", false, options);
    }

    private static ReportColumn text(String key, String label) {
        return new ReportColumn(key, label, "text");
    }

    private static ReportColumn number(String key, String label) {
        return new ReportColumn(key, label, "number");
    }

    private static ReportColumn money(String key, String label) {
        return new ReportColumn(key, label, "money");
    }

    private static ReportColumn date(String key, String label) {
        return new ReportColumn(key, label, "date");
    }

    private static ReportColumn pct(String key, String label) {
        return new ReportColumn(key, label, "percent");
    }
}
