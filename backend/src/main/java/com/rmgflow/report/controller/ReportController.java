package com.rmgflow.report.controller;

import com.rmgflow.common.ApiException;
import com.rmgflow.report.dto.ReportDefinitionResponse;
import com.rmgflow.report.dto.ReportResultResponse;
import com.rmgflow.report.service.ReportExportService;
import com.rmgflow.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Document 14 reports: catalog, run (JSON) and export (CSV/PDF). Filters are plain
 * query parameters named by each report's filter keys; per-report module/financial
 * permission checks happen in ReportService.
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('REPORT_VIEW')")
public class ReportController {

    private static final MediaType TEXT_CSV = new MediaType("text", "csv", java.nio.charset.StandardCharsets.UTF_8);

    private final ReportService reportService;
    private final ReportExportService reportExportService;

    @GetMapping
    public List<ReportDefinitionResponse> list() {
        return reportService.list();
    }

    @GetMapping("/{code}")
    public ReportResultResponse run(@PathVariable String code, @RequestParam Map<String, String> filters) {
        return reportService.run(code, filters);
    }

    @GetMapping("/{code}/export")
    public ResponseEntity<byte[]> export(@PathVariable String code, @RequestParam String format,
                                         @RequestParam Map<String, String> params) {
        Map<String, String> filters = new HashMap<>(params);
        filters.remove("format");
        String normalized = format.toLowerCase();
        if (!normalized.equals("csv") && !normalized.equals("pdf")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "format must be csv or pdf");
        }

        ReportResultResponse report = reportService.run(code, filters);
        List<String> filterLines = reportService.describeFilters(code, filters);
        byte[] body = normalized.equals("csv")
                ? reportExportService.toCsv(report, filterLines)
                : reportExportService.toPdf(report, filterLines);
        String fileName = code + "-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE) + "." + normalized;

        return ResponseEntity.ok()
                .contentType(normalized.equals("csv") ? TEXT_CSV : MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(fileName).build().toString())
                .contentLength(body.length)
                .body(body);
    }
}
