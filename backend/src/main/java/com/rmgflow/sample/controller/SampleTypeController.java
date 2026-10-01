package com.rmgflow.sample.controller;

import com.rmgflow.sample.entity.SampleType;
import com.rmgflow.sample.repository.SampleTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 9 §9/36: sample types are data-driven (standard + buyer-specific), not hardcoded. */
@RestController
@RequestMapping("/api/v1/sample-types")
@RequiredArgsConstructor
public class SampleTypeController {

    private final SampleTypeRepository sampleTypeRepository;

    @GetMapping
    public List<SampleType> list() {
        return sampleTypeRepository.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public SampleType create(@RequestBody SampleType sampleType) {
        sampleType.setId(null);
        return sampleTypeRepository.save(sampleType);
    }
}
