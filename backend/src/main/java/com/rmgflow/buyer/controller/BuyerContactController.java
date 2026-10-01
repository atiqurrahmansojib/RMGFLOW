package com.rmgflow.buyer.controller;

import com.rmgflow.buyer.dto.BuyerContactRequest;
import com.rmgflow.buyer.dto.BuyerContactResponse;
import com.rmgflow.buyer.service.BuyerContactService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/buyers/{buyerId}/contacts")
@RequiredArgsConstructor
public class BuyerContactController {

    private final BuyerContactService buyerContactService;

    @GetMapping
    @PreAuthorize("hasAuthority('BUYER_VIEW')")
    public List<BuyerContactResponse> list(@PathVariable Long buyerId) {
        return buyerContactService.list(buyerId);
    }

    @PostMapping
    @PreAuthorize("hasAnyAuthority('BUYER_MANAGE', 'BUYER_MANAGE_OWN')")
    public ResponseEntity<BuyerContactResponse> create(@PathVariable Long buyerId, @Valid @RequestBody BuyerContactRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(buyerContactService.create(buyerId, request));
    }
}
