package com.rmgflow.order.controller;

import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.order.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @GetMapping
    @PreAuthorize("hasAuthority('ORDER_VIEW')")
    public Page<OrderResponse> list(@RequestParam(required = false) Long buyerId,
                                     @RequestParam(required = false) OrderStatus status, Pageable pageable) {
        return orderService.list(buyerId, status, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ORDER_VIEW')")
    public OrderResponse get(@PathVariable Long id) {
        return orderService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ORDER_CREATE')")
    public ResponseEntity<OrderResponse> create(@Valid @RequestBody OrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(orderService.create(request));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAuthority('ORDER_CANCEL_APPROVE')")
    public ResponseEntity<Void> cancel(@PathVariable Long id, @RequestParam String reason) {
        orderService.cancel(id, reason);
        return ResponseEntity.noContent().build();
    }
}
