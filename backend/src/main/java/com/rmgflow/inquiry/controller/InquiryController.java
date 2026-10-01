package com.rmgflow.inquiry.controller;

import com.rmgflow.inquiry.dto.InquiryRequest;
import com.rmgflow.inquiry.dto.InquiryResponse;
import com.rmgflow.inquiry.dto.MarkWonLostRequest;
import com.rmgflow.inquiry.entity.InquiryStatus;
import com.rmgflow.inquiry.service.InquiryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/inquiries")
@RequiredArgsConstructor
public class InquiryController {

    private final InquiryService inquiryService;

    @GetMapping
    @PreAuthorize("hasAuthority('INQUIRY_VIEW')")
    public Page<InquiryResponse> list(@RequestParam(required = false) InquiryStatus status, Pageable pageable) {
        return inquiryService.list(status, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('INQUIRY_VIEW')")
    public InquiryResponse get(@PathVariable Long id) {
        return inquiryService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('INQUIRY_MANAGE')")
    public ResponseEntity<InquiryResponse> create(@Valid @RequestBody InquiryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(inquiryService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('INQUIRY_MANAGE')")
    public InquiryResponse update(@PathVariable Long id, @Valid @RequestBody InquiryRequest request) {
        return inquiryService.update(id, request);
    }

    /** Document 10.1/Doc 7 #27: the Mark Won/Lost/Hold/Quoted transition, state-machine enforced. */
    @PostMapping("/{id}/status")
    @PreAuthorize("hasAuthority('INQUIRY_MANAGE')")
    public InquiryResponse changeStatus(@PathVariable Long id, @Valid @RequestBody MarkWonLostRequest request) {
        return inquiryService.changeStatus(id, request);
    }
}
