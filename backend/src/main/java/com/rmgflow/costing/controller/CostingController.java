package com.rmgflow.costing.controller;

import com.rmgflow.costing.dto.CostingRequest;
import com.rmgflow.costing.dto.CostingResponse;
import com.rmgflow.costing.service.CostingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/costings")
@RequiredArgsConstructor
public class CostingController {

    private final CostingService costingService;

    @GetMapping
    @PreAuthorize("hasAuthority('COSTING_VIEW')")
    public Page<CostingResponse> list(@RequestParam(required = false) Long styleId, Pageable pageable) {
        return costingService.list(styleId, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('COSTING_VIEW')")
    public CostingResponse get(@PathVariable Long id) {
        return costingService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('COSTING_MANAGE')")
    public ResponseEntity<CostingResponse> create(@Valid @RequestBody CostingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(costingService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('COSTING_MANAGE')")
    public CostingResponse updateDraft(@PathVariable Long id, @Valid @RequestBody CostingRequest request) {
        return costingService.updateDraft(id, request);
    }

    /** Document 9.1: the only way to change an APPROVED costing's numbers — a brand new version. */
    @PostMapping("/{id}/revise")
    @PreAuthorize("hasAuthority('COSTING_MANAGE')")
    public ResponseEntity<CostingResponse> createRevision(@PathVariable Long id, @Valid @RequestBody CostingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(costingService.createRevision(id, request));
    }

    @PostMapping("/{id}/submit")
    @PreAuthorize("hasAuthority('COSTING_MANAGE')")
    public CostingResponse submitForApproval(@PathVariable Long id) {
        return costingService.submitForApproval(id);
    }

    /** Document 10.2: called after the corresponding Approval round is decided APPROVED
     * (via POST /api/v1/approvals/{id}/decide) — COSTING_APPROVE-gated there, not here,
     * since the approval engine owns the decision; this just flips the costing's own
     * status once that decision has been made. */
    @PostMapping("/{id}/mark-approved")
    @PreAuthorize("hasAuthority('COSTING_APPROVE')")
    public CostingResponse markApproved(@PathVariable Long id) {
        return costingService.markApproved(id);
    }
}
