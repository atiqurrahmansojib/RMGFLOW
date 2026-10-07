package com.rmgflow.factory.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.factory.repository.FactoryRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.masterdata.repository.CountryRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.security.scope.AccessScope;
import com.rmgflow.security.scope.AccessScopeService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Document 21 P2-T4: unlike buyers, factory create/edit has no "own factory" junior
 * concept at this stage (Doc 5.2 — Factory Coordinator's scoped access applies to
 * production-follow-up data in later phases, not to the master record itself). */
@Service
@RequiredArgsConstructor
public class FactoryService {

    private final FactoryRepository factoryRepository;
    private final AccessScopeService accessScopeService;
    private final OrganizationRepository organizationRepository;
    private final CountryRepository countryRepository;
    private final AuditService auditService;

    @Transactional
    public FactoryResponse create(FactoryRequest request) {
        if (factoryRepository.existsByCodeIgnoreCase(request.code())) {
            throw new ApiException(HttpStatus.CONFLICT, "A factory with this code already exists");
        }
        Factory factory = new Factory();
        factory.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        applyRequest(factory, request);
        factory = factoryRepository.save(factory);
        auditService.record("FACTORY_CREATE", "Factory", factory.getId(), null, toResponse(factory), null);
        return toResponse(factory);
    }

    @Transactional
    public FactoryResponse update(Long factoryId, FactoryRequest request) {
        Factory factory = findInCurrentOrganization(factoryId);

        if (request.version() == null || request.version() != factory.getVersion()) {
            throw new ApiException(HttpStatus.CONFLICT, "Factory was modified by another user; refresh and retry");
        }

        FactoryResponse before = toResponse(factory);
        applyRequest(factory, request);
        // saveAndFlush: see BuyerService.update's comment on the same pattern (Doc 8.12).
        factory = factoryRepository.saveAndFlush(factory);
        auditService.record("FACTORY_UPDATE", "Factory", factory.getId(), before, toResponse(factory), null);
        return toResponse(factory);
    }

    @Transactional(readOnly = true)
    public FactoryResponse get(Long factoryId) {
        return toResponse(findInCurrentOrganization(factoryId));
    }

    @Transactional(readOnly = true)
    public Page<FactoryResponse> list(PartnerType partnerType, Pageable pageable) {
        AccessScope scope = accessScopeService.current();
        return factoryRepository.findVisible(currentUser().organizationId(), partnerType, scope.allFactories(), scope.factoryIdsParam(), pageable).map(this::toResponse);
    }

    @Transactional
    public void deactivate(Long factoryId) {
        Factory factory = findInCurrentOrganization(factoryId);
        factory.setActive(false);
        factoryRepository.save(factory);
        auditService.record("FACTORY_DEACTIVATE", "Factory", factory.getId(), null, null, null);
    }

    /** Security review fix: a factory id from another organization must 404 — same
     * treatment as BuyerService.findInCurrentOrganization. Public so other modules
     * (InquiryFactoryCandidateService, etc.) can resolve a factory within the
     * caller's tenant without re-deriving the same check. */
    public Factory findInCurrentOrganization(Long factoryId) {
        // Doc 5.3: tenant AND object-level scope — an out-of-scope record is a 404, same as a missing one.
        AccessScope scope = accessScopeService.current();
        return factoryRepository.findVisibleById(factoryId, currentUser().organizationId(), scope.allFactories(), scope.factoryIdsParam())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Factory not found"));
    }

    private void applyRequest(Factory factory, FactoryRequest request) {
        factory.setCode(request.code());
        factory.setName(request.name());
        factory.setPartnerType(request.partnerType());
        factory.setLegalEntityName(request.legalEntityName());
        factory.setAddress(request.address());
        factory.setCountry(request.country() != null ? countryRepository.getReferenceById(request.country()) : null);
        factory.setCapacityPerMonth(request.capacityPerMonth());
    }

    private FactoryResponse toResponse(Factory factory) {
        return new FactoryResponse(
                factory.getId(), factory.getCode(), factory.getName(), factory.getPartnerType(),
                factory.getLegalEntityName(), factory.getAddress(),
                factory.getCountry() != null ? factory.getCountry().getCode() : null,
                factory.getCapacityPerMonth(), factory.isActive(), factory.getVersion());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
