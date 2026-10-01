package com.rmgflow.order.controller;

import com.rmgflow.order.dto.OrderAmendmentRequest;
import com.rmgflow.order.dto.OrderAmendmentResponse;
import com.rmgflow.order.service.OrderAmendmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/amendments")
@RequiredArgsConstructor
public class OrderAmendmentController {

    private final OrderAmendmentService orderAmendmentService;

    @GetMapping
    @PreAuthorize("hasAuthority('ORDER_VIEW')")
    public List<OrderAmendmentResponse> list(@PathVariable Long orderId) {
        return orderAmendmentService.list(orderId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ORDER_AMEND_REQUEST')")
    public ResponseEntity<OrderAmendmentResponse> request(@PathVariable Long orderId, @Valid @RequestBody OrderAmendmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(orderAmendmentService.request(orderId, request));
    }

    @PostMapping("/{amendmentId}/approve")
    @PreAuthorize("hasAuthority('ORDER_AMEND_APPROVE')")
    public OrderAmendmentResponse approve(@PathVariable Long orderId, @PathVariable Long amendmentId) {
        return orderAmendmentService.decide(orderId, amendmentId, true);
    }

    @PostMapping("/{amendmentId}/reject")
    @PreAuthorize("hasAuthority('ORDER_AMEND_APPROVE')")
    public OrderAmendmentResponse reject(@PathVariable Long orderId, @PathVariable Long amendmentId) {
        return orderAmendmentService.decide(orderId, amendmentId, false);
    }
}
