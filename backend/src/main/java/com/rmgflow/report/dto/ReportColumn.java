package com.rmgflow.report.dto;

/** {@code type} is text|number|money|date|percent — tells clients/exports how to format the value. */
public record ReportColumn(String key, String label, String type) {
}
