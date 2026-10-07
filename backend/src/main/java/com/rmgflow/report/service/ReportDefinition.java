package com.rmgflow.report.service;

import com.rmgflow.report.dto.ReportColumn;
import com.rmgflow.report.dto.ReportFilterResponse;

import java.util.List;

/**
 * One entry of the report registry (Document 14). {@code moduleAuthority} is the
 * permission of the module the report reads from — a user needs it (or
 * REPORT_VIEW_ALL) so a report never exposes data the module's own screens would
 * hide. {@code financial} reports additionally require REPORT_FINANCIAL_VIEW.
 */
public record ReportDefinition(String code, String name, String category, String description,
                               List<ReportFilterResponse> filters, String moduleAuthority, boolean financial,
                               List<ReportColumn> columns, ReportQuery query) {

    @FunctionalInterface
    public interface ReportQuery {
        ReportData run(ReportParams params);
    }
}
