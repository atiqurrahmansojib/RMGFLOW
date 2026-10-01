package com.rmgflow.sample.controller;

import com.rmgflow.sample.dto.SampleRequest;
import com.rmgflow.sample.dto.SampleResponse;
import com.rmgflow.sample.entity.SampleStatus;
import com.rmgflow.sample.service.SampleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/samples")
@RequiredArgsConstructor
public class SampleController {

    private final SampleService sampleService;

    @GetMapping
    @PreAuthorize("hasAuthority('SAMPLE_VIEW')")
    public Page<SampleResponse> list(@RequestParam(required = false) SampleStatus status, Pageable pageable) {
        return sampleService.list(status, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('SAMPLE_VIEW')")
    public SampleResponse get(@PathVariable Long id) {
        return sampleService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('SAMPLE_MANAGE')")
    public ResponseEntity<SampleResponse> create(@Valid @RequestBody SampleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sampleService.create(request));
    }
}
