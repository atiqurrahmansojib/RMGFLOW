package com.rmgflow.claim.controller;

import com.rmgflow.claim.dto.ClaimRequest;
import com.rmgflow.claim.dto.ClaimResolutionRequest;
import com.rmgflow.claim.dto.ClaimResponse;
import com.rmgflow.claim.service.ClaimService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ClaimController {

    private final ClaimService claimService;

    @GetMapping("/api/v1/claims")
    @PreAuthorize("hasAuthority('CLAIM_VIEW')")
    public List<ClaimResponse> listAll() {
        return claimService.listAll();
    }

    @GetMapping("/api/v1/orders/{orderId}/claims")
    @PreAuthorize("hasAuthority('CLAIM_VIEW')")
    public List<ClaimResponse> listByOrder(@PathVariable Long orderId) {
        return claimService.listByOrder(orderId);
    }

    @PostMapping("/api/v1/orders/{orderId}/claims")
    @PreAuthorize("hasAuthority('CLAIM_MANAGE')")
    public ResponseEntity<ClaimResponse> create(@PathVariable Long orderId, @Valid @RequestBody ClaimRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(claimService.create(orderId, request));
    }

    @PostMapping("/api/v1/claims/{id}/resolve")
    @PreAuthorize("hasAuthority('CLAIM_MANAGE')")
    public ClaimResponse resolve(@PathVariable Long id, @Valid @RequestBody ClaimResolutionRequest request) {
        return claimService.resolve(id, request);
    }
}
