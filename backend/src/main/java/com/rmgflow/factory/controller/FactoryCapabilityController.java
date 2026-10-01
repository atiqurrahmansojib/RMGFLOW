package com.rmgflow.factory.controller;

import com.rmgflow.factory.dto.FactoryCapabilityRequest;
import com.rmgflow.factory.dto.FactoryCapabilityResponse;
import com.rmgflow.factory.service.FactoryCapabilityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/factories/{factoryId}/capabilities")
@RequiredArgsConstructor
public class FactoryCapabilityController {

    private final FactoryCapabilityService factoryCapabilityService;

    @GetMapping
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public List<FactoryCapabilityResponse> list(@PathVariable Long factoryId) {
        return factoryCapabilityService.list(factoryId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public ResponseEntity<FactoryCapabilityResponse> create(@PathVariable Long factoryId, @Valid @RequestBody FactoryCapabilityRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(factoryCapabilityService.create(factoryId, request));
    }
}
