package com.rmgflow.report.dto;

import java.util.List;

/** Catalog entry for GET /api/v1/reports. */
public record ReportDefinitionResponse(String code, String name, String category, String description,
                                       List<ReportFilterResponse> filters) {
}
