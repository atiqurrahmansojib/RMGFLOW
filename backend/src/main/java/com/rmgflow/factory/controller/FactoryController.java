package com.rmgflow.factory.controller;

import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.factory.service.FactoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/factories")
@RequiredArgsConstructor
public class FactoryController {

    private final FactoryService factoryService;

    @GetMapping
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public Page<FactoryResponse> list(@RequestParam(required = false) PartnerType partnerType, Pageable pageable) {
        return factoryService.list(partnerType, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public FactoryResponse get(@PathVariable Long id) {
        return factoryService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public ResponseEntity<FactoryResponse> create(@Valid @RequestBody FactoryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(factoryService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public FactoryResponse update(@PathVariable Long id, @Valid @RequestBody FactoryRequest request) {
        return factoryService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public ResponseEntity<Void> deactivate(@PathVariable Long id) {
        factoryService.deactivate(id);
        return ResponseEntity.noContent().build();
    }
}
