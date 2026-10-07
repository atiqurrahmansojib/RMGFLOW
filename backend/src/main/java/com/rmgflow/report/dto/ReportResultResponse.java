package com.rmgflow.report.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

/** Result of running a report: column metadata, rows keyed by column key, and a summary block. */
public record ReportResultResponse(String code, String name, OffsetDateTime generatedAt, List<ReportColumn> columns,
                                   List<Map<String, Object>> rows, List<ReportSummaryItem> summary) {
}
