package com.rmgflow.approval.controller;

import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.dto.ApprovalResponse;
import com.rmgflow.approval.entity.ApprovalTargetType;
import com.rmgflow.approval.service.ApprovalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Document 7 (#67-69)/11.2: generic approval endpoints, parameterized by target type —
 * the Pending Approvals Inbox (#67) and Approval Detail/Action (#68) screens hit these
 * directly rather than each module having its own approve/reject endpoint.
 * Authorization here is intentionally coarse (any authenticated user can view history/
 * submit); the module-specific service (CostingService, etc.) is what gates WHETHER a
 * given target can be submitted, and decide() is further gated per target type by
 * the calling module's own permission check before it ever reaches here in later
 * phases — Phase 4 wires COSTING_APPROVE/QUOTATION_APPROVE at the Costing/Quotation
 * controller level around the submit/decide calls for those two target types.
 */
@RestController
@RequestMapping("/api/v1/approvals")
@RequiredArgsConstructor
public class ApprovalController {

    private final ApprovalService approvalService;

    @GetMapping
    public Page<ApprovalResponse> inbox(@RequestParam(required = false) ApprovalTargetType targetType, Pageable pageable) {
        return approvalService.pendingInbox(targetType, pageable);
    }

    @GetMapping("/history")
    public List<ApprovalResponse> history(@RequestParam ApprovalTargetType targetType, @RequestParam Long targetId) {
        return approvalService.history(targetType, targetId);
    }

    @PostMapping("/{id}/decide")
    public ApprovalResponse decide(@PathVariable Long id, @Valid @RequestBody ApprovalDecisionRequest request) {
        return approvalService.decide(id, request);
    }
}
