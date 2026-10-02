package com.rmgflow.ta.controller;

import com.rmgflow.ta.dto.RecordActualDateRequest;
import com.rmgflow.ta.dto.TaMilestoneResponse;
import com.rmgflow.ta.service.TaMilestoneService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 7 (#54-58): the order's T&A calendar — generation, viewing, actual-date recording. */
@RestController
@RequestMapping("/api/v1/orders/{orderId}/ta-milestones")
@RequiredArgsConstructor
public class TaMilestoneController {

    private final TaMilestoneService taMilestoneService;

    @GetMapping
    @PreAuthorize("hasAuthority('TA_VIEW')")
    public List<TaMilestoneResponse> list(@PathVariable Long orderId) {
        return taMilestoneService.list(orderId);
    }

    /** Document A15: usually called automatically on order confirmation (OrderService);
     * exposed here too for templates added/corrected after the fact. */
    @PostMapping("/generate")
    @PreAuthorize("hasAuthority('TA_TEMPLATE_MANAGE')")
    public ResponseEntity<List<TaMilestoneResponse>> generate(@PathVariable Long orderId, @RequestParam Long styleId) {
        return ResponseEntity.ok(taMilestoneService.instantiateForOrder(orderId, styleId));
    }

    @PostMapping("/{milestoneId}/actual-date")
    @PreAuthorize("hasAuthority('TA_UPDATE')")
    public TaMilestoneResponse recordActualDate(@PathVariable Long orderId, @PathVariable Long milestoneId,
                                                 @Valid @RequestBody RecordActualDateRequest request) {
        return taMilestoneService.recordActualDate(milestoneId, request);
    }

    @PostMapping("/{milestoneId}/responsible-user")
    @PreAuthorize("hasAuthority('TA_TEMPLATE_MANAGE')")
    public TaMilestoneResponse assignResponsibleUser(@PathVariable Long orderId, @PathVariable Long milestoneId, @RequestParam Long userId) {
        return taMilestoneService.assignResponsibleUser(milestoneId, userId);
    }
}
