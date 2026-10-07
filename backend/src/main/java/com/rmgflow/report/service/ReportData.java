package com.rmgflow.report.service;

import com.rmgflow.report.dto.ReportSummaryItem;

import java.util.List;
import java.util.Map;

/** Raw output of a report query, before column-type normalization. */
public record ReportData(List<Map<String, Object>> rows, List<ReportSummaryItem> summary) {
}
