package com.rmgflow.financial.controller;

import com.rmgflow.financial.dto.PaymentRecordRequest;
import com.rmgflow.financial.dto.PaymentRecordResponse;
import com.rmgflow.financial.service.PaymentRecordService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payment-records")
@RequiredArgsConstructor
public class PaymentRecordController {

    private final PaymentRecordService paymentRecordService;

    @PostMapping
    @PreAuthorize("hasAuthority('FINANCIAL_MANAGE')")
    public ResponseEntity<PaymentRecordResponse> record(@Valid @RequestBody PaymentRecordRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(paymentRecordService.record(request));
    }
}
