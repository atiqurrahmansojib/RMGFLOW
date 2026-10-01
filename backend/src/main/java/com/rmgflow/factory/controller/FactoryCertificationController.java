package com.rmgflow.factory.controller;

import com.rmgflow.factory.dto.FactoryCertificationRequest;
import com.rmgflow.factory.dto.FactoryCertificationResponse;
import com.rmgflow.factory.service.FactoryCertificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/factories/{factoryId}/certifications")
@RequiredArgsConstructor
public class FactoryCertificationController {

    private final FactoryCertificationService factoryCertificationService;

    @GetMapping
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public List<FactoryCertificationResponse> list(@PathVariable Long factoryId) {
        return factoryCertificationService.list(factoryId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public ResponseEntity<FactoryCertificationResponse> create(@PathVariable Long factoryId, @Valid @RequestBody FactoryCertificationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(factoryCertificationService.create(factoryId, request));
    }
}
