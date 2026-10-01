package com.rmgflow.ta.controller;

import com.rmgflow.ta.dto.TaTemplateMilestoneRequest;
import com.rmgflow.ta.dto.TaTemplateMilestoneResponse;
import com.rmgflow.ta.dto.TaTemplateRequest;
import com.rmgflow.ta.dto.TaTemplateResponse;
import com.rmgflow.ta.service.TaTemplateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ta-templates")
@RequiredArgsConstructor
public class TaTemplateController {

    private final TaTemplateService taTemplateService;

    @GetMapping
    @PreAuthorize("hasAuthority('TA_VIEW')")
    public List<TaTemplateResponse> list() {
        return taTemplateService.list();
    }

    @PostMapping
    @PreAuthorize("hasAuthority('TA_TEMPLATE_MANAGE')")
    public ResponseEntity<TaTemplateResponse> create(@Valid @RequestBody TaTemplateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(taTemplateService.create(request));
    }

    @GetMapping("/{id}/milestones")
    @PreAuthorize("hasAuthority('TA_VIEW')")
    public List<TaTemplateMilestoneResponse> listMilestones(@PathVariable Long id) {
        return taTemplateService.listMilestones(id);
    }

    @PostMapping("/{id}/milestones")
    @PreAuthorize("hasAuthority('TA_TEMPLATE_MANAGE')")
    public ResponseEntity<TaTemplateMilestoneResponse> addMilestone(@PathVariable Long id, @Valid @RequestBody TaTemplateMilestoneRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(taTemplateService.addMilestone(id, request));
    }
}
