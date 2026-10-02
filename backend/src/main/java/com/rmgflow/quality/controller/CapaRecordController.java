package com.rmgflow.quality.controller;

import com.rmgflow.quality.dto.CapaFactoryResponseRequest;
import com.rmgflow.quality.dto.CapaRecordRequest;
import com.rmgflow.quality.dto.CapaRecordResponse;
import com.rmgflow.quality.service.CapaRecordService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/capa-records")
@RequiredArgsConstructor
public class CapaRecordController {

    private final CapaRecordService capaRecordService;

    @GetMapping
    @PreAuthorize("hasAuthority('QUALITY_VIEW')")
    public List<CapaRecordResponse> list(@RequestParam(required = false) Long defectId, @RequestParam(required = false) Long inspectionId) {
        if (defectId != null) {
            return capaRecordService.listByDefect(defectId);
        }
        return capaRecordService.listByInspection(inspectionId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('QUALITY_MANAGE')")
    public ResponseEntity<CapaRecordResponse> create(@Valid @RequestBody CapaRecordRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(capaRecordService.create(request));
    }

    @PostMapping("/{id}/factory-response")
    @PreAuthorize("hasAuthority('QUALITY_MANAGE')")
    public CapaRecordResponse recordFactoryResponse(@PathVariable Long id, @Valid @RequestBody CapaFactoryResponseRequest request) {
        return capaRecordService.recordFactoryResponse(id, request);
    }

    @PostMapping("/{id}/close")
    @PreAuthorize("hasAuthority('QUALITY_MANAGE')")
    public CapaRecordResponse close(@PathVariable Long id) {
        return capaRecordService.close(id);
    }
}
