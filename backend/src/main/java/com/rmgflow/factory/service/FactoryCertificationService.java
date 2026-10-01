package com.rmgflow.factory.service;

import com.rmgflow.factory.dto.FactoryCertificationRequest;
import com.rmgflow.factory.dto.FactoryCertificationResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryCertification;
import com.rmgflow.factory.repository.FactoryCertificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 9.9/13 (A12): expiry is computed at read-time via FactoryCertification.isExpired(),
 * surfaced here so the document-expiry notification job (Phase 12) has a single source to scan. */
@Service
@RequiredArgsConstructor
public class FactoryCertificationService {

    private final FactoryCertificationRepository factoryCertificationRepository;
    private final FactoryService factoryService;

    @Transactional
    public FactoryCertificationResponse create(Long factoryId, FactoryCertificationRequest request) {
        // Security review fix: tenant-scoped lookup before anything else.
        Factory factory = factoryService.findInCurrentOrganization(factoryId);

        FactoryCertification cert = new FactoryCertification();
        cert.setFactory(factory);
        cert.setCertName(request.certName());
        cert.setIssuedDate(request.issuedDate());
        cert.setExpiryDate(request.expiryDate());
        cert.setDocumentId(request.documentId());
        cert = factoryCertificationRepository.save(cert);
        return toResponse(cert);
    }

    @Transactional(readOnly = true)
    public List<FactoryCertificationResponse> list(Long factoryId) {
        factoryService.findInCurrentOrganization(factoryId);
        return factoryCertificationRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryCertificationResponse toResponse(FactoryCertification cert) {
        return new FactoryCertificationResponse(cert.getId(), cert.getFactory().getId(), cert.getCertName(),
                cert.getIssuedDate(), cert.getExpiryDate(), cert.getDocumentId(), cert.isExpired());
    }
}
