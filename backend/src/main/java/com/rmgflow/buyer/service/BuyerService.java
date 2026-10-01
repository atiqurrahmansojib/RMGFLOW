package com.rmgflow.buyer.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.repository.BuyerRepository;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.repository.AssignmentRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.identity.service.AssignmentService;
import com.rmgflow.masterdata.repository.CountryRepository;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.masterdata.repository.IncotermRepository;
import com.rmgflow.masterdata.repository.PaymentTermRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * Document 5.2/9 (buyer rows aren't subject to the immutability invariants that
 * apply to costing/quotation/order — those protect finalized commercial decisions;
 * a buyer record is just evolving master data). The one access-control nuance is
 * Document 5.3's object-level scoping for JUNIOR_MERCHANDISER: they may create a
 * buyer (becoming auto-assigned to it) but can only edit buyers they're assigned to.
 */
@Service
@RequiredArgsConstructor
public class BuyerService {

    private final BuyerRepository buyerRepository;
    private final OrganizationRepository organizationRepository;
    private final CountryRepository countryRepository;
    private final CurrencyRepository currencyRepository;
    private final PaymentTermRepository paymentTermRepository;
    private final IncotermRepository incotermRepository;
    private final AssignmentRepository assignmentRepository;
    private final AssignmentService assignmentService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public BuyerResponse create(BuyerRequest request) {
        if (buyerRepository.existsByCodeIgnoreCase(request.code())) {
            throw new ApiException(HttpStatus.CONFLICT, "A buyer with this code already exists");
        }

        Buyer buyer = new Buyer();
        buyer.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        applyRequest(buyer, request);
        buyer = buyerRepository.save(buyer);

        if (hasRole("JUNIOR_MERCHANDISER") && !hasAnyRole("GENERAL_MANAGER", "OWNER_MD", "SENIOR_MERCHANDISER")) {
            Assignment assignment = new Assignment();
            assignment.setUser(userRepository.getReferenceById(currentUser().id()));
            assignment.setScopeType(ScopeType.BUYER);
            assignment.setScopeId(buyer.getId());
            assignmentRepository.save(assignment);
        }

        auditService.record("BUYER_CREATE", "Buyer", buyer.getId(), null, toResponse(buyer), null);
        return toResponse(buyer);
    }

    @Transactional
    public BuyerResponse update(Long buyerId, BuyerRequest request) {
        Buyer buyer = buyerRepository.findById(buyerId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Buyer not found"));

        requireEditAccess(buyer);

        if (request.version() == null || request.version() != buyer.getVersion()) {
            throw new ApiException(HttpStatus.CONFLICT, "Buyer was modified by another user; refresh and retry");
        }

        BuyerResponse before = toResponse(buyer);
        applyRequest(buyer, request);
        // saveAndFlush (not save): the @Version bump only lands on the in-memory field
        // at flush time (Doc 8.12) — without forcing it here, the response below would
        // echo back the pre-update version instead of the one actually persisted.
        buyer = buyerRepository.saveAndFlush(buyer);

        auditService.record("BUYER_UPDATE", "Buyer", buyer.getId(), before, toResponse(buyer), null);
        return toResponse(buyer);
    }

    @Transactional(readOnly = true)
    public BuyerResponse get(Long buyerId) {
        return buyerRepository.findById(buyerId)
                .map(this::toResponse)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Buyer not found"));
    }

    @Transactional(readOnly = true)
    public Page<BuyerResponse> list(String search, Pageable pageable) {
        Page<Buyer> page = StringUtils.hasText(search)
                ? buyerRepository.findByActiveTrueAndNameContainingIgnoreCase(search, pageable)
                : buyerRepository.findByActiveTrue(pageable);
        return page.map(this::toResponse);
    }

    @Transactional
    public void deactivate(Long buyerId) {
        Buyer buyer = buyerRepository.findById(buyerId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Buyer not found"));
        requireEditAccess(buyer);
        buyer.setActive(false);
        buyerRepository.save(buyer);
        auditService.record("BUYER_DEACTIVATE", "Buyer", buyer.getId(), null, null, null);
    }

    private void requireEditAccess(Buyer buyer) {
        if (hasAnyRole("SUPER_ADMIN", "GENERAL_MANAGER", "OWNER_MD", "SENIOR_MERCHANDISER")) {
            return;
        }
        if (hasRole("JUNIOR_MERCHANDISER") && assignmentService.hasBuyerAccess(currentUser(), buyer.getId())) {
            return;
        }
        throw new AccessDeniedException("Not permitted to edit this buyer");
    }

    private void applyRequest(Buyer buyer, BuyerRequest request) {
        buyer.setCode(request.code());
        buyer.setName(request.name());
        buyer.setGroupName(request.groupName());
        buyer.setCountry(request.country() != null ? countryRepository.getReferenceById(request.country()) : null);
        buyer.setDefaultCurrency(request.defaultCurrency() != null ? currencyRepository.getReferenceById(request.defaultCurrency()) : null);
        buyer.setDefaultPaymentTerms(request.defaultPaymentTermsId() != null ? paymentTermRepository.getReferenceById(request.defaultPaymentTermsId()) : null);
        buyer.setDefaultIncoterm(request.defaultIncoterm() != null ? incotermRepository.getReferenceById(request.defaultIncoterm()) : null);
    }

    private BuyerResponse toResponse(Buyer buyer) {
        return new BuyerResponse(
                buyer.getId(),
                buyer.getCode(),
                buyer.getName(),
                buyer.getGroupName(),
                buyer.getCountry() != null ? buyer.getCountry().getCode() : null,
                buyer.getDefaultCurrency() != null ? buyer.getDefaultCurrency().getCode() : null,
                buyer.getDefaultPaymentTerms() != null ? buyer.getDefaultPaymentTerms().getId() : null,
                buyer.getDefaultIncoterm() != null ? buyer.getDefaultIncoterm().getCode() : null,
                buyer.isActive(),
                buyer.getVersion()
        );
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }

    private boolean hasRole(String role) {
        return SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    private boolean hasAnyRole(String... roles) {
        for (String role : roles) {
            if (hasRole(role)) return true;
        }
        return false;
    }
}
