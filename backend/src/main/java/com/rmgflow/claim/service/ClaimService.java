package com.rmgflow.claim.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.claim.dto.ClaimRequest;
import com.rmgflow.claim.dto.ClaimResolutionRequest;
import com.rmgflow.claim.dto.ClaimResponse;
import com.rmgflow.claim.entity.Claim;
import com.rmgflow.claim.entity.ClaimStatus;
import com.rmgflow.claim.repository.ClaimRepository;
import com.rmgflow.common.ApiException;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.shipment.service.ShipmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Document 9.11/10.8: a claim's resolution never alters the original shipment/order
 * commercial records (see Claim entity javadoc) — this service has no dependency
 * injected that would let it write to Order/Shipment fields, by construction.
 */
@Service
@RequiredArgsConstructor
public class ClaimService {

    private static final Set<ClaimStatus> RESOLVABLE_FROM = EnumSet.of(ClaimStatus.OPEN, ClaimStatus.UNDER_REVIEW);

    private final ClaimRepository claimRepository;
    private final OrderService orderService;
    private final ShipmentService shipmentService;
    private final AuditService auditService;

    @Transactional
    public ClaimResponse create(Long orderId, ClaimRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);

        Claim claim = new Claim();
        claim.setOrder(order);
        if (request.shipmentId() != null) {
            claim.setShipment(shipmentService.findInCurrentOrganization(request.shipmentId()));
        }
        claim.setRaisedBy(request.raisedBy());
        claim.setClaimType(request.claimType());
        claim.setDescription(request.description());
        claim.setClaimedAmount(request.claimedAmount());
        claim = claimRepository.save(claim);

        auditService.record("CLAIM_CREATE", "Order", orderId, null, toResponse(claim), null);
        return toResponse(claim);
    }

    @Transactional
    public ClaimResponse resolve(Long claimId, ClaimResolutionRequest request) {
        Claim claim = findInCurrentOrganization(claimId);
        if (!RESOLVABLE_FROM.contains(claim.getStatus())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "This claim is already " + claim.getStatus());
        }
        if (request.status() != ClaimStatus.RESOLVED && request.status() != ClaimStatus.REJECTED && request.status() != ClaimStatus.UNDER_REVIEW) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid resolution status: " + request.status());
        }

        ClaimStatus before = claim.getStatus();
        claim.setStatus(request.status());
        claim.setResolution(request.resolution());
        if (request.status() == ClaimStatus.RESOLVED || request.status() == ClaimStatus.REJECTED) {
            claim.setResolvedAt(Instant.now());
        }
        claim = claimRepository.save(claim);

        auditService.record("CLAIM_RESOLVE", "Claim", claim.getId(), before, claim.getStatus(), request.resolution());
        return toResponse(claim);
    }

    @Transactional(readOnly = true)
    public List<ClaimResponse> listByOrder(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return claimRepository.findByOrderId(orderId).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<ClaimResponse> listAll() {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return claimRepository.findByOrder_Organization_Id(organizationId).stream().map(this::toResponse).toList();
    }

    private Claim findInCurrentOrganization(Long claimId) {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return claimRepository.findByIdAndOrder_Organization_Id(claimId, organizationId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Claim not found"));
    }

    private ClaimResponse toResponse(Claim claim) {
        return new ClaimResponse(claim.getId(), claim.getOrder().getId(),
                claim.getShipment() != null ? claim.getShipment().getId() : null, claim.getRaisedBy(), claim.getClaimType(),
                claim.getDescription(), claim.getClaimedAmount(), claim.getStatus(), claim.getResolution(),
                claim.getCreatedAt(), claim.getResolvedAt());
    }
}
