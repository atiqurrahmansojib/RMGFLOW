package com.rmgflow.factory.controller;

import com.rmgflow.factory.dto.FactoryContactRequest;
import com.rmgflow.factory.dto.FactoryContactResponse;
import com.rmgflow.factory.service.FactoryContactService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/factories/{factoryId}/contacts")
@RequiredArgsConstructor
public class FactoryContactController {

    private final FactoryContactService factoryContactService;

    @GetMapping
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public List<FactoryContactResponse> list(@PathVariable Long factoryId) {
        return factoryContactService.list(factoryId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('FACTORY_MANAGE')")
    public ResponseEntity<FactoryContactResponse> create(@PathVariable Long factoryId, @Valid @RequestBody FactoryContactRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(factoryContactService.create(factoryId, request));
    }
}
