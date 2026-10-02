package com.rmgflow.quality.controller;

import com.rmgflow.quality.dto.DefectRequest;
import com.rmgflow.quality.dto.DefectResponse;
import com.rmgflow.quality.service.DefectService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inspections/{inspectionId}/defects")
@RequiredArgsConstructor
public class DefectController {

    private final DefectService defectService;

    @GetMapping
    @PreAuthorize("hasAuthority('QUALITY_VIEW')")
    public List<DefectResponse> list(@PathVariable Long inspectionId) {
        return defectService.list(inspectionId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('QUALITY_MANAGE')")
    public ResponseEntity<DefectResponse> create(@PathVariable Long inspectionId, @Valid @RequestBody DefectRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(defectService.create(inspectionId, request));
    }
}
