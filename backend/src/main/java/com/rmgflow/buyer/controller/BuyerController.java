package com.rmgflow.buyer.controller;

import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.buyer.service.BuyerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/** Document 11.2: /api/v1/buyers. Doc 5.2 permission matrix: view is broad, manage is role/scope gated in BuyerService. */
@RestController
@RequestMapping("/api/v1/buyers")
@RequiredArgsConstructor
public class BuyerController {

    private final BuyerService buyerService;

    @GetMapping
    @PreAuthorize("hasAuthority('BUYER_VIEW')")
    public Page<BuyerResponse> list(@RequestParam(required = false) String search, Pageable pageable) {
        return buyerService.list(search, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('BUYER_VIEW')")
    public BuyerResponse get(@PathVariable Long id) {
        return buyerService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAnyAuthority('BUYER_MANAGE', 'BUYER_MANAGE_OWN')")
    public ResponseEntity<BuyerResponse> create(@Valid @RequestBody BuyerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(buyerService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('BUYER_MANAGE', 'BUYER_MANAGE_OWN')")
    public BuyerResponse update(@PathVariable Long id, @Valid @RequestBody BuyerRequest request) {
        return buyerService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('BUYER_MANAGE', 'BUYER_MANAGE_OWN')")
    public ResponseEntity<Void> deactivate(@PathVariable Long id) {
        buyerService.deactivate(id);
        return ResponseEntity.noContent().build();
    }
}
