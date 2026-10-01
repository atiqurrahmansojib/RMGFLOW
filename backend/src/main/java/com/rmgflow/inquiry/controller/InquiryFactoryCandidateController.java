package com.rmgflow.inquiry.controller;

import com.rmgflow.inquiry.dto.InquiryFactoryCandidateRequest;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateResponse;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateStatusRequest;
import com.rmgflow.inquiry.service.InquiryFactoryCandidateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inquiries/{inquiryId}/factory-candidates")
@RequiredArgsConstructor
public class InquiryFactoryCandidateController {

    private final InquiryFactoryCandidateService candidateService;

    @GetMapping
    @PreAuthorize("hasAuthority('INQUIRY_VIEW')")
    public List<InquiryFactoryCandidateResponse> list(@PathVariable Long inquiryId) {
        return candidateService.list(inquiryId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('INQUIRY_MANAGE')")
    public ResponseEntity<InquiryFactoryCandidateResponse> create(@PathVariable Long inquiryId, @Valid @RequestBody InquiryFactoryCandidateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(candidateService.create(inquiryId, request));
    }

    @PutMapping("/{candidateId}/status")
    @PreAuthorize("hasAuthority('INQUIRY_MANAGE')")
    public InquiryFactoryCandidateResponse updateStatus(@PathVariable Long inquiryId, @PathVariable Long candidateId,
                                                         @Valid @RequestBody InquiryFactoryCandidateStatusRequest request) {
        return candidateService.updateStatus(inquiryId, candidateId, request);
    }
}
