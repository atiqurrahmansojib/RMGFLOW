package com.rmgflow.factory.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.repository.BuyerRepository;
import com.rmgflow.common.ApiException;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryBuyerApprovalResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryBuyerApproval;
import com.rmgflow.factory.repository.FactoryBuyerApprovalRepository;
import com.rmgflow.factory.repository.FactoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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
    private final FactoryRepository factoryRepository;
    private final BuyerRepository buyerRepository;
    private final AuditService auditService;

    @Transactional
    public FactoryBuyerApprovalResponse upsert(Long factoryId, FactoryBuyerApprovalRequest request) {
        Factory factory = factoryRepository.findById(factoryId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Factory not found"));
        var buyer = buyerRepository.findById(request.buyerId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Buyer not found"));

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

    @Transactional(readOnly = true)
    public List<FactoryBuyerApprovalResponse> list(Long factoryId) {
        return factoryBuyerApprovalRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryBuyerApprovalResponse toResponse(FactoryBuyerApproval approval) {
        return new FactoryBuyerApprovalResponse(approval.getId(), approval.getFactory().getId(),
                approval.getBuyer().getId(), approval.getStatus(), approval.getApprovedDate(), approval.getExpiryDate());
    }
}
