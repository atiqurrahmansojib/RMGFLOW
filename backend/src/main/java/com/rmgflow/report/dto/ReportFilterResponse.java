package com.rmgflow.report.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

/** One filter a report accepts. {@code type} is date|buyer|factory|status|text; {@code options} only for status. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ReportFilterResponse(String key, String label, String type, boolean required, List<String> options) {
}
