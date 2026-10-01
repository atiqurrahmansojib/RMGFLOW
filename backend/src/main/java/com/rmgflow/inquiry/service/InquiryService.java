package com.rmgflow.inquiry.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.inquiry.dto.InquiryRequest;
import com.rmgflow.inquiry.dto.InquiryResponse;
import com.rmgflow.inquiry.dto.MarkWonLostRequest;
import com.rmgflow.inquiry.entity.Inquiry;
import com.rmgflow.inquiry.entity.InquiryStatus;
import com.rmgflow.inquiry.repository.InquiryRepository;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.masterdata.repository.SeasonRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * Document 10.1: enforces the inquiry state machine server-side — the prompt's own
 * example flow (OPEN -> QUOTED -> WON/LOST, HOLD as a pause from either) is NOT just
 * a UI suggestion, a client could otherwise PUT any status directly.
 */
@Service
@RequiredArgsConstructor
public class InquiryService {

    private static final Map<InquiryStatus, Set<InquiryStatus>> VALID_TRANSITIONS = Map.of(
            // Document 10.1: WON is reached via QUOTED, not directly from OPEN — a real
            // buying house always formally quotes before a buyer confirms a PO.
            InquiryStatus.OPEN, EnumSet.of(InquiryStatus.QUOTED, InquiryStatus.LOST, InquiryStatus.HOLD),
            InquiryStatus.QUOTED, EnumSet.of(InquiryStatus.WON, InquiryStatus.LOST, InquiryStatus.HOLD),
            InquiryStatus.HOLD, EnumSet.of(InquiryStatus.OPEN, InquiryStatus.QUOTED, InquiryStatus.LOST),
            InquiryStatus.WON, EnumSet.noneOf(InquiryStatus.class),
            InquiryStatus.LOST, EnumSet.noneOf(InquiryStatus.class)
    );

    private final InquiryRepository inquiryRepository;
    private final BuyerService buyerService;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final SeasonRepository seasonRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditService auditService;

    @Transactional
    public InquiryResponse create(InquiryRequest request) {
        if (inquiryRepository.existsByInquiryNoIgnoreCase(request.inquiryNo())) {
            throw new ApiException(HttpStatus.CONFLICT, "An inquiry with this number already exists");
        }
        // Security review lesson applied up front (Doc 18 ADR-10): the buyer must
        // resolve within the caller's organization, not just exist anywhere.
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());

        Inquiry inquiry = new Inquiry();
        inquiry.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        inquiry.setInquiryNo(request.inquiryNo());
        inquiry.setBuyer(buyer);
        applyOptionalFields(inquiry, request);
        inquiry = inquiryRepository.save(inquiry);

        auditService.record("INQUIRY_CREATE", "Inquiry", inquiry.getId(), null, toResponse(inquiry), null);
        return toResponse(inquiry);
    }

    @Transactional
    public InquiryResponse update(Long inquiryId, InquiryRequest request) {
        Inquiry inquiry = findInCurrentOrganization(inquiryId);
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());

        InquiryResponse before = toResponse(inquiry);
        inquiry.setBuyer(buyer);
        applyOptionalFields(inquiry, request);
        inquiry = inquiryRepository.save(inquiry);

        auditService.record("INQUIRY_UPDATE", "Inquiry", inquiry.getId(), before, toResponse(inquiry), null);
        return toResponse(inquiry);
    }

    @Transactional
    public InquiryResponse changeStatus(Long inquiryId, MarkWonLostRequest request) {
        Inquiry inquiry = findInCurrentOrganization(inquiryId);

        Set<InquiryStatus> allowed = VALID_TRANSITIONS.getOrDefault(inquiry.getStatus(), Set.of());
        if (!allowed.contains(request.status())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Cannot transition inquiry from " + inquiry.getStatus() + " to " + request.status());
        }
        // Document 10.1/FR-20, enforced redundantly here AND by the DB CHECK constraint
        // (chk_inquiries_lost_reason) — defense in depth, same pattern as costing immutability.
        if (request.status() == InquiryStatus.LOST && (request.lostReason() == null || request.lostReason().isBlank())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "lostReason is required when marking an inquiry LOST");
        }

        InquiryStatus before = inquiry.getStatus();
        inquiry.setStatus(request.status());
        inquiry.setLostReason(request.status() == InquiryStatus.LOST ? request.lostReason() : null);
        inquiry = inquiryRepository.save(inquiry);

        auditService.record("INQUIRY_STATUS_CHANGE", "Inquiry", inquiry.getId(), before, inquiry.getStatus(), request.lostReason());
        return toResponse(inquiry);
    }

    @Transactional(readOnly = true)
    public InquiryResponse get(Long inquiryId) {
        return toResponse(findInCurrentOrganization(inquiryId));
    }

    @Transactional(readOnly = true)
    public Page<InquiryResponse> list(InquiryStatus status, Pageable pageable) {
        Long organizationId = currentUser().organizationId();
        Page<Inquiry> page = status != null
                ? inquiryRepository.findByOrganizationIdAndStatus(organizationId, status, pageable)
                : inquiryRepository.findByOrganizationId(organizationId, pageable);
        return page.map(this::toResponse);
    }

    public Inquiry findInCurrentOrganization(Long inquiryId) {
        return inquiryRepository.findByIdAndOrganizationId(inquiryId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Inquiry not found"));
    }

    private void applyOptionalFields(Inquiry inquiry, InquiryRequest request) {
        // Seasons are shared, non-tenant-scoped reference data (Doc 8.3) — existence-only
        // check is enough. Merchandiser assignment is different: it links to a real user
        // account, so it must be verified within the caller's own organization (security
        // review fix) — a bare getReferenceById would let an inquiry be silently assigned
        // to another organization's user id with no existence or tenancy check at all.
        if (request.seasonId() != null) {
            if (!seasonRepository.existsById(request.seasonId())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Season not found");
            }
            inquiry.setSeason(seasonRepository.getReferenceById(request.seasonId()));
        } else {
            inquiry.setSeason(null);
        }

        if (request.merchandiserId() != null) {
            var merchandiser = userRepository.findByIdAndOrganizationId(request.merchandiserId(), currentUser().organizationId())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Merchandiser not found"));
            inquiry.setMerchandiser(merchandiser);
        } else {
            inquiry.setMerchandiser(null);
        }

        inquiry.setTargetQuantity(request.targetQuantity());
        inquiry.setTargetPrice(request.targetPrice());
        if (request.targetCurrency() != null) {
            if (!currencyRepository.existsById(request.targetCurrency())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
            }
            inquiry.setTargetCurrency(currencyRepository.getReferenceById(request.targetCurrency()));
        } else {
            inquiry.setTargetCurrency(null);
        }
        inquiry.setDeliveryRequirement(request.deliveryRequirement());
    }

    private InquiryResponse toResponse(Inquiry inquiry) {
        return new InquiryResponse(
                inquiry.getId(), inquiry.getInquiryNo(), inquiry.getBuyer().getId(), inquiry.getBuyer().getName(),
                inquiry.getSeason() != null ? inquiry.getSeason().getId() : null,
                inquiry.getMerchandiser() != null ? inquiry.getMerchandiser().getId() : null,
                inquiry.getTargetQuantity(), inquiry.getTargetPrice(),
                inquiry.getTargetCurrency() != null ? inquiry.getTargetCurrency().getCode() : null,
                inquiry.getDeliveryRequirement(), inquiry.getStatus(), inquiry.getLostReason());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
