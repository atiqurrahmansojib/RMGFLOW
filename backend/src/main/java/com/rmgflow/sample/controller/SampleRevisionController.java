package com.rmgflow.sample.controller;

import com.rmgflow.sample.dto.SampleRevisionRequest;
import com.rmgflow.sample.dto.SampleRevisionResponse;
import com.rmgflow.sample.service.SampleRevisionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 7 (#32-36)/9.3: no update endpoint for a revision — only create(). */
@RestController
@RequestMapping("/api/v1/samples/{sampleId}/revisions")
@RequiredArgsConstructor
public class SampleRevisionController {

    private final SampleRevisionService sampleRevisionService;

    @GetMapping
    @PreAuthorize("hasAuthority('SAMPLE_VIEW')")
    public List<SampleRevisionResponse> list(@PathVariable Long sampleId) {
        return sampleRevisionService.list(sampleId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('SAMPLE_MANAGE')")
    public ResponseEntity<SampleRevisionResponse> create(@PathVariable Long sampleId, @RequestBody SampleRevisionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sampleRevisionService.create(sampleId, request));
    }

    /** Document 10.5: call after deciding the latest revision's approval round
     * (POST /api/v1/approvals/{id}/decide) to roll the decision up onto the sample. */
    @PostMapping("/sync-status")
    @PreAuthorize("hasAuthority('SAMPLE_APPROVE')")
    public SampleRevisionResponse syncStatus(@PathVariable Long sampleId) {
        return sampleRevisionService.syncStatusFromLatestApproval(sampleId);
    }
}
