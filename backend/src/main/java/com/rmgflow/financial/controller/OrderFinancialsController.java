package com.rmgflow.financial.controller;

import com.rmgflow.financial.dto.OrderFinancialsRequest;
import com.rmgflow.financial.dto.OrderFinancialsResponse;
import com.rmgflow.financial.service.OrderFinancialsService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/financials")
@RequiredArgsConstructor
public class OrderFinancialsController {

    private final OrderFinancialsService orderFinancialsService;

    @GetMapping
    @PreAuthorize("hasAuthority('FINANCIAL_VIEW')")
    public OrderFinancialsResponse get(@PathVariable Long orderId) {
        return orderFinancialsService.get(orderId);
    }

    @PutMapping
    @PreAuthorize("hasAuthority('FINANCIAL_MANAGE')")
    public OrderFinancialsResponse upsert(@PathVariable Long orderId, @RequestBody OrderFinancialsRequest request) {
        return orderFinancialsService.upsert(orderId, request);
    }
}
