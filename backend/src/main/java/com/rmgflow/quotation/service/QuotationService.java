package com.rmgflow.quotation.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.costing.entity.Costing;
import com.rmgflow.costing.entity.CostingStatus;
import com.rmgflow.costing.service.CostingService;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.masterdata.repository.IncotermRepository;
import com.rmgflow.masterdata.repository.PaymentTermRepository;
import com.rmgflow.quotation.dto.QuotationRequest;
import com.rmgflow.quotation.dto.QuotationResponse;
import com.rmgflow.quotation.entity.Quotation;
import com.rmgflow.quotation.entity.QuotationStatus;
import com.rmgflow.quotation.repository.QuotationRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.style.entity.Style;
import com.rmgflow.style.service.StyleService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/**
 * Document 9.2/10.2: a quotation may only reference an APPROVED costing (enforced
 * here, server-side — FR-60/61); once APPROVED itself, it's immutable (DB trigger,
 * V14 migration, same defense-in-depth pattern as costing).
 */
@Service
@RequiredArgsConstructor
public class QuotationService {

    private static final Set<QuotationStatus> EDITABLE = EnumSet.of(QuotationStatus.DRAFT, QuotationStatus.NEGOTIATING);

    private final QuotationRepository quotationRepository;
    private final CostingService costingService;
    private final BuyerService buyerService;
    private final StyleService styleService;
    private final OrganizationRepository organizationRepository;
    private final CurrencyRepository currencyRepository;
    private final IncotermRepository incotermRepository;
    private final PaymentTermRepository paymentTermRepository;
    private final AuditService auditService;

    @Transactional
    public QuotationResponse create(QuotationRequest request) {
        Costing costing = costingService.findInCurrentOrganization(request.costingId());
        if (costing.getStatus() != CostingStatus.APPROVED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "A quotation can only be created from an APPROVED costing");
        }
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());
        Style style = styleService.findInCurrentOrganization(request.styleId());
        if (!currencyRepository.existsById(request.currency())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
        }

        String quotationNo = request.quotationNo() != null && !request.quotationNo().isBlank()
                ? request.quotationNo()
                : "QTN-" + UUID.randomUUID();
        if (quotationRepository.existsByQuotationNoIgnoreCase(quotationNo)) {
            throw new ApiException(HttpStatus.CONFLICT, "A quotation with this number already exists");
        }

        Quotation quotation = new Quotation();
        quotation.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        quotation.setCosting(costing);
        quotation.setQuotationNo(quotationNo);
        quotation.setVersionNo(1);
        quotation.setBuyer(buyer);
        quotation.setStyle(style);
        applyOptionalFields(quotation, request);
        quotation = quotationRepository.save(quotation);

        auditService.record("QUOTATION_CREATE", "Quotation", quotation.getId(), null, toResponse(quotation), null);
        return toResponse(quotation);
    }

    /** Document 9.2: buyer counter-offer -> new version referencing the prior one;
     * the prior row is marked SUPERSEDED only if it wasn't already APPROVED (an
     * APPROVED row is immutable, the trigger would block it anyway). */
    @Transactional
    public QuotationResponse createRevision(Long sourceQuotationId, QuotationRequest request) {
        Quotation source = findInCurrentOrganization(sourceQuotationId);

        Quotation revision = new Quotation();
        revision.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        revision.setCosting(costingService.findInCurrentOrganization(request.costingId()));
        revision.setQuotationNo(source.getQuotationNo());
        revision.setVersionNo(source.getVersionNo() + 1);
        revision.setBuyer(buyerService.findInCurrentOrganization(request.buyerId()));
        revision.setStyle(styleService.findInCurrentOrganization(request.styleId()));
        revision.setSupersedesQuotation(source);
        applyOptionalFields(revision, request);
        revision = quotationRepository.save(revision);

        if (source.getStatus() != QuotationStatus.APPROVED) {
            source.setStatus(QuotationStatus.SUPERSEDED);
            quotationRepository.save(source);
        }

        auditService.record("QUOTATION_REVISE", "Quotation", revision.getId(), source.getId(), toResponse(revision), null);
        return toResponse(revision);
    }

    @Transactional
    public QuotationResponse updateStatus(Long quotationId, QuotationStatus newStatus) {
        Quotation quotation = findInCurrentOrganization(quotationId);
        if (!EDITABLE.contains(quotation.getStatus()) && newStatus != QuotationStatus.EXPIRED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Cannot change status of a quotation that is " + quotation.getStatus());
        }
        QuotationStatus before = quotation.getStatus();
        quotation.setStatus(newStatus);
        quotation = quotationRepository.save(quotation);
        auditService.record("QUOTATION_STATUS_CHANGE", "Quotation", quotation.getId(), before, newStatus, null);
        return toResponse(quotation);
    }

    @Transactional(readOnly = true)
    public QuotationResponse get(Long quotationId) {
        return toResponse(findInCurrentOrganization(quotationId));
    }

    @Transactional(readOnly = true)
    public Page<QuotationResponse> list(Long buyerId, Pageable pageable) {
        Long organizationId = currentUser().organizationId();
        Page<Quotation> page = buyerId != null
                ? quotationRepository.findByOrganizationIdAndBuyerId(organizationId, buyerId, pageable)
                : quotationRepository.findByOrganizationId(organizationId, pageable);
        return page.map(this::toResponse);
    }

    public Quotation findInCurrentOrganization(Long quotationId) {
        return quotationRepository.findByIdAndOrganizationId(quotationId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Quotation not found"));
    }

    private void applyOptionalFields(Quotation quotation, QuotationRequest request) {
        quotation.setQuantity(request.quantity());
        quotation.setUnitPrice(request.unitPrice());
        quotation.setCurrency(currencyRepository.getReferenceById(request.currency()));
        if (request.incoterm() != null) {
            if (!incotermRepository.existsById(request.incoterm())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Incoterm not found");
            }
            quotation.setIncoterm(incotermRepository.getReferenceById(request.incoterm()));
        } else {
            quotation.setIncoterm(null);
        }
        if (request.paymentTermsId() != null) {
            if (!paymentTermRepository.existsById(request.paymentTermsId())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Payment term not found");
            }
            quotation.setPaymentTerms(paymentTermRepository.getReferenceById(request.paymentTermsId()));
        } else {
            quotation.setPaymentTerms(null);
        }
        quotation.setValidityDate(request.validityDate());
        quotation.setLeadTimeDays(request.leadTimeDays());
    }

    private QuotationResponse toResponse(Quotation quotation) {
        return new QuotationResponse(
                quotation.getId(), quotation.getCosting().getId(), quotation.getQuotationNo(), quotation.getVersionNo(),
                quotation.getBuyer().getId(), quotation.getStyle().getId(), quotation.getQuantity(), quotation.getUnitPrice(),
                quotation.getCurrency().getCode(), quotation.getIncoterm() != null ? quotation.getIncoterm().getCode() : null,
                quotation.getPaymentTerms() != null ? quotation.getPaymentTerms().getId() : null,
                quotation.getValidityDate(), quotation.getLeadTimeDays(), quotation.getStatus(),
                quotation.getSupersedesQuotation() != null ? quotation.getSupersedesQuotation().getId() : null,
                quotation.getVersion());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
