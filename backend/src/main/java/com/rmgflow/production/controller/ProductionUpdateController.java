package com.rmgflow.production.controller;

import com.rmgflow.production.dto.ProductionProgressResponse;
import com.rmgflow.production.dto.ProductionUpdateRequest;
import com.rmgflow.production.dto.ProductionUpdateResponse;
import com.rmgflow.production.service.ProductionUpdateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/production-updates")
@RequiredArgsConstructor
public class ProductionUpdateController {

    private final ProductionUpdateService productionUpdateService;

    @GetMapping
    @PreAuthorize("hasAuthority('PRODUCTION_VIEW')")
    public ProductionProgressResponse progress(@PathVariable Long orderId) {
        return productionUpdateService.progress(orderId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('PRODUCTION_UPDATE')")
    public ResponseEntity<ProductionUpdateResponse> recordDailyUpdate(@PathVariable Long orderId, @Valid @RequestBody ProductionUpdateRequest request) {
        return ResponseEntity.status(HttpStatus.OK).body(productionUpdateService.recordDailyUpdate(orderId, request));
    }
}
