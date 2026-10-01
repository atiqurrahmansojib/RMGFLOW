package com.rmgflow.quotation.controller;

import com.rmgflow.quotation.dto.QuotationRequest;
import com.rmgflow.quotation.dto.QuotationResponse;
import com.rmgflow.quotation.entity.QuotationStatus;
import com.rmgflow.quotation.service.QuotationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/quotations")
@RequiredArgsConstructor
public class QuotationController {

    private final QuotationService quotationService;

    @GetMapping
    @PreAuthorize("hasAuthority('QUOTATION_VIEW')")
    public Page<QuotationResponse> list(@RequestParam(required = false) Long buyerId, Pageable pageable) {
        return quotationService.list(buyerId, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('QUOTATION_VIEW')")
    public QuotationResponse get(@PathVariable Long id) {
        return quotationService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('QUOTATION_MANAGE')")
    public ResponseEntity<QuotationResponse> create(@Valid @RequestBody QuotationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(quotationService.create(request));
    }

    @PostMapping("/{id}/revise")
    @PreAuthorize("hasAuthority('QUOTATION_MANAGE')")
    public ResponseEntity<QuotationResponse> createRevision(@PathVariable Long id, @Valid @RequestBody QuotationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(quotationService.createRevision(id, request));
    }

    @PostMapping("/{id}/status")
    @PreAuthorize("hasAuthority('QUOTATION_MANAGE')")
    public QuotationResponse updateStatus(@PathVariable Long id, @RequestParam QuotationStatus status) {
        return quotationService.updateStatus(id, status);
    }
}
