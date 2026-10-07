package com.rmgflow.sample.controller;

import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.sample.dto.SampleTypeRequest;
import com.rmgflow.sample.dto.SampleTypeResponse;
import com.rmgflow.sample.entity.SampleType;
import com.rmgflow.sample.repository.SampleTypeRepository;
import com.rmgflow.security.AuthenticatedUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 9 §9/36: sample types are data-driven (standard + buyer-specific), not hardcoded.
 *  Returns DTOs, not the entity: the entity's lazy Buyer would otherwise be serialized and a
 *  buyer-specific type of another organization would be visible to everyone. */
@RestController
@RequestMapping("/api/v1/sample-types")
@RequiredArgsConstructor
public class SampleTypeController {

    private final SampleTypeRepository sampleTypeRepository;
    private final BuyerService buyerService;

    @GetMapping
    @Transactional(readOnly = true)
    public List<SampleTypeResponse> list(@AuthenticationPrincipal AuthenticatedUser user) {
        return sampleTypeRepository.findVisibleToOrganization(user.organizationId()).stream()
                .map(SampleTypeController::toResponse).toList();
    }

    @PostMapping
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    @Transactional
    public ResponseEntity<SampleTypeResponse> create(@Valid @RequestBody SampleTypeRequest request) {
        SampleType sampleType = new SampleType();
        sampleType.setName(request.name().trim());
        if (request.buyerId() != null) {
            sampleType.setBuyer(buyerService.findInCurrentOrganization(request.buyerId()));
            sampleType.setBuyerSpecific(true);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(sampleTypeRepository.save(sampleType)));
    }

    private static SampleTypeResponse toResponse(SampleType type) {
        return new SampleTypeResponse(type.getId(), type.getName(), type.isBuyerSpecific(),
                type.getBuyer() != null ? type.getBuyer().getId() : null);
    }
}
