package com.rmgflow.report.service;

import com.rmgflow.report.dto.ReportSummaryItem;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;
import java.util.function.Predicate;

/** Helpers that compute a report's summary block (totals/counts/averages) from its rows. */
final class Summaries {

    private Summaries() {
    }

    static ReportSummaryItem item(String label, Object value) {
        return new ReportSummaryItem(label, value);
    }

    static long count(List<Map<String, Object>> rows, Predicate<Map<String, Object>> predicate) {
        return rows.stream().filter(predicate).count();
    }

    static long countEq(List<Map<String, Object>> rows, String key, Object value) {
        return count(rows, r -> Objects.equals(String.valueOf(r.get(key)), String.valueOf(value)));
    }

    static BigDecimal sum(List<Map<String, Object>> rows, String key) {
        return rows.stream()
                .map(r -> toDecimal(r.get(key)))
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }

    static long sumLong(List<Map<String, Object>> rows, String key) {
        return rows.stream().map(r -> toDecimal(r.get(key))).filter(Objects::nonNull).mapToLong(BigDecimal::longValue).sum();
    }

    /** Average of the non-null values in a column, or null when there are none. */
    static BigDecimal avg(List<Map<String, Object>> rows, String key) {
        List<BigDecimal> values = rows.stream().map(r -> toDecimal(r.get(key))).filter(Objects::nonNull).toList();
        if (values.isEmpty()) {
            return null;
        }
        return values.stream().reduce(BigDecimal.ZERO, BigDecimal::add)
                .divide(BigDecimal.valueOf(values.size()), 2, RoundingMode.HALF_UP);
    }

    /** {@code part / whole * 100} rounded to 2 dp, or null when whole is zero. */
    static BigDecimal percent(long part, long whole) {
        if (whole == 0) {
            return null;
        }
        return BigDecimal.valueOf(part * 100.0 / whole).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Money totals must not mix currencies, so one summary line is produced per
     * currency (e.g. "Total value (USD)"). Rows with a null amount are skipped.
     */
    static List<ReportSummaryItem> sumByCurrency(List<Map<String, Object>> rows, String label, String amountKey,
                                                 String currencyKey) {
        Map<String, BigDecimal> totals = new TreeMap<>();
        for (Map<String, Object> row : rows) {
            BigDecimal amount = toDecimal(row.get(amountKey));
            if (amount == null) {
                continue;
            }
            String currency = row.get(currencyKey) == null ? "N/A" : row.get(currencyKey).toString();
            totals.merge(currency, amount, BigDecimal::add);
        }
        List<ReportSummaryItem> items = new ArrayList<>();
        if (totals.isEmpty()) {
            items.add(item(label, BigDecimal.ZERO.setScale(2)));
        }
        totals.forEach((currency, total) -> items.add(item(label + " (" + currency + ")", total.setScale(2, RoundingMode.HALF_UP))));
        return items;
    }

    static BigDecimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof BigDecimal decimal) {
            return decimal;
        }
        if (value instanceof Number number) {
            return new BigDecimal(number.toString());
        }
        return null;
    }
}
