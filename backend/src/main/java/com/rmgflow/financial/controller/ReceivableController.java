package com.rmgflow.financial.controller;

import com.rmgflow.financial.dto.ReceivableRequest;
import com.rmgflow.financial.dto.ReceivableResponse;
import com.rmgflow.financial.service.ReceivableService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ReceivableController {

    private final ReceivableService receivableService;

    @GetMapping("/api/v1/receivables")
    @PreAuthorize("hasAuthority('FINANCIAL_VIEW')")
    public List<ReceivableResponse> listAll() {
        return receivableService.listAll();
    }

    @GetMapping("/api/v1/orders/{orderId}/receivables")
    @PreAuthorize("hasAuthority('FINANCIAL_VIEW')")
    public List<ReceivableResponse> listByOrder(@PathVariable Long orderId) {
        return receivableService.listByOrder(orderId);
    }

    @PostMapping("/api/v1/orders/{orderId}/receivables")
    @PreAuthorize("hasAuthority('FINANCIAL_MANAGE')")
    public ResponseEntity<ReceivableResponse> create(@PathVariable Long orderId, @Valid @RequestBody ReceivableRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(receivableService.create(orderId, request));
    }
}
