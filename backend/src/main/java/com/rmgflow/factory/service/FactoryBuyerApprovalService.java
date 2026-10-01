package com.rmgflow.factory.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryBuyerApprovalResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryBuyerApproval;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.repository.FactoryBuyerApprovalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Document 9.4/21 P2-T5: this is the data OrderService (Phase 6) will check before
 * allowing a factory to be assigned to a buyer's order. Getting this right now
 * matters more than it looks — it's a compliance gate, not a convenience flag.
 */
@Service
@RequiredArgsConstructor
public class FactoryBuyerApprovalService {

    private final FactoryBuyerApprovalRepository factoryBuyerApprovalRepository;
    private final FactoryService factoryService;
    private final BuyerService buyerService;
    private final AuditService auditService;

    @Transactional
    public FactoryBuyerApprovalResponse upsert(Long factoryId, FactoryBuyerApprovalRequest request) {
        // Security review fix: both the factory AND the buyer must resolve within the
        // caller's organization — a cross-org id on either side must 404, not let the
        // caller create an approval record linking to data outside their tenant.
        Factory factory = factoryService.findInCurrentOrganization(factoryId);
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());

        FactoryBuyerApproval approval = factoryBuyerApprovalRepository
                .findByFactoryIdAndBuyerId(factoryId, request.buyerId())
                .orElseGet(FactoryBuyerApproval::new);
        var previousStatus = approval.getStatus();
        approval.setFactory(factory);
        approval.setBuyer(buyer);
        approval.setStatus(request.status());
        approval.setApprovedDate(request.approvedDate());
        approval.setExpiryDate(request.expiryDate());
        approval = factoryBuyerApprovalRepository.save(approval);

        auditService.record("FACTORY_BUYER_APPROVAL_SET", "FactoryBuyerApproval", approval.getId(),
                previousStatus, approval.getStatus(), null);
        return toResponse(approval);
    }

    /** Document 9.4: the exact hard-gate check OrderService calls before allowing a
     * factory onto a buyer's order — kept here (not a raw repository query from
     * OrderService) so the compliance rule has exactly one implementation. */
    @Transactional(readOnly = true)
    public boolean isApprovedForBuyer(Long factoryId, Long buyerId) {
        return factoryBuyerApprovalRepository.existsByFactoryIdAndBuyerIdAndStatus(
                factoryId, buyerId, FactoryBuyerApprovalStatus.APPROVED);
    }

    @Transactional(readOnly = true)
    public List<FactoryBuyerApprovalResponse> list(Long factoryId) {
        factoryService.findInCurrentOrganization(factoryId);
        return factoryBuyerApprovalRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryBuyerApprovalResponse toResponse(FactoryBuyerApproval approval) {
        return new FactoryBuyerApprovalResponse(approval.getId(), approval.getFactory().getId(),
                approval.getBuyer().getId(), approval.getStatus(), approval.getApprovedDate(), approval.getExpiryDate());
    }
}
