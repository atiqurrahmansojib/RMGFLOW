package com.rmgflow.financial.controller;

import com.rmgflow.financial.dto.PayableRequest;
import com.rmgflow.financial.dto.PayableResponse;
import com.rmgflow.financial.service.PayableService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class PayableController {

    private final PayableService payableService;

    @GetMapping("/api/v1/payables")
    @PreAuthorize("hasAuthority('FINANCIAL_VIEW')")
    public List<PayableResponse> listAll() {
        return payableService.listAll();
    }

    @GetMapping("/api/v1/orders/{orderId}/payables")
    @PreAuthorize("hasAuthority('FINANCIAL_VIEW')")
    public List<PayableResponse> listByOrder(@PathVariable Long orderId) {
        return payableService.listByOrder(orderId);
    }

    @PostMapping("/api/v1/orders/{orderId}/payables")
    @PreAuthorize("hasAuthority('FINANCIAL_MANAGE')")
    public ResponseEntity<PayableResponse> create(@PathVariable Long orderId, @Valid @RequestBody PayableRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(payableService.create(orderId, request));
    }
}
