package com.rmgflow.factory.controller;

import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryBuyerApprovalResponse;
import com.rmgflow.factory.service.FactoryBuyerApprovalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 9.4/21 P2-T5: the compliance gate data OrderService reads in Phase 6. */
@RestController
@RequestMapping("/api/v1/factories/{factoryId}/buyer-approvals")
@RequiredArgsConstructor
public class FactoryBuyerApprovalController {

    private final FactoryBuyerApprovalService factoryBuyerApprovalService;

    @GetMapping
    @PreAuthorize("hasAuthority('FACTORY_VIEW')")
    public List<FactoryBuyerApprovalResponse> list(@PathVariable Long factoryId) {
        return factoryBuyerApprovalService.list(factoryId);
    }

    @PutMapping
    @PreAuthorize("hasAuthority('FACTORY_APPROVE_FOR_BUYER')")
    public FactoryBuyerApprovalResponse upsert(@PathVariable Long factoryId, @Valid @RequestBody FactoryBuyerApprovalRequest request) {
        return factoryBuyerApprovalService.upsert(factoryId, request);
    }
}
