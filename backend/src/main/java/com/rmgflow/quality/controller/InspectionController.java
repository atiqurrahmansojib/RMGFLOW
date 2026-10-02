package com.rmgflow.quality.controller;

import com.rmgflow.quality.dto.InspectionRequest;
import com.rmgflow.quality.dto.InspectionResponse;
import com.rmgflow.quality.service.InspectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/inspections")
@RequiredArgsConstructor
public class InspectionController {

    private final InspectionService inspectionService;

    @GetMapping
    @PreAuthorize("hasAuthority('QUALITY_VIEW')")
    public List<InspectionResponse> list(@PathVariable Long orderId) {
        return inspectionService.list(orderId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('QUALITY_MANAGE')")
    public ResponseEntity<InspectionResponse> create(@PathVariable Long orderId, @Valid @RequestBody InspectionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(inspectionService.create(orderId, request));
    }
}
