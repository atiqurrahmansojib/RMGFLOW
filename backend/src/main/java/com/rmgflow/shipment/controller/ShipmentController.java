package com.rmgflow.shipment.controller;

import com.rmgflow.shipment.dto.ShipmentRequest;
import com.rmgflow.shipment.dto.ShipmentResponse;
import com.rmgflow.shipment.entity.ShipmentStatus;
import com.rmgflow.shipment.service.ShipmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/orders/{orderId}/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentService shipmentService;

    @GetMapping
    @PreAuthorize("hasAuthority('SHIPMENT_VIEW')")
    public List<ShipmentResponse> list(@PathVariable Long orderId) {
        return shipmentService.list(orderId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('SHIPMENT_MANAGE')")
    public ResponseEntity<ShipmentResponse> create(@PathVariable Long orderId, @Valid @RequestBody ShipmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(shipmentService.create(orderId, request));
    }

    @PostMapping("/{shipmentId}/status")
    @PreAuthorize("hasAuthority('SHIPMENT_MANAGE')")
    public ShipmentResponse updateStatus(@PathVariable Long orderId, @PathVariable Long shipmentId, @RequestParam ShipmentStatus status) {
        return shipmentService.updateStatus(shipmentId, status);
    }
}
