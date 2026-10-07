package com.rmgflow.costing.service;

import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;
import com.rmgflow.approval.service.ApprovalDecidedEvent;
import com.rmgflow.approval.service.ApprovalService;
import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.costing.dto.*;
import com.rmgflow.costing.entity.Costing;
import com.rmgflow.costing.entity.CostingItem;
import com.rmgflow.costing.entity.CostingStatus;
import com.rmgflow.costing.repository.CostingItemRepository;
import com.rmgflow.costing.repository.CostingRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.inquiry.service.InquiryService;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.security.scope.AccessScope;
import com.rmgflow.security.scope.AccessScopeService;
import com.rmgflow.style.service.StyleService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Document 9.1/10.2/ADR-14: all cost/margin math happens HERE, server-side, never
 * trusted from the client (NFR-01/FR-52). Once a costing reaches APPROVED, this
 * service never issues another UPDATE to it or its items — a revision is always a
 * new row (Doc 9.1/ADR-14), backed by the DB trigger in V13 as a second line of
 * defense.
 */
@Service
@RequiredArgsConstructor
public class CostingService {

    private final CostingRepository costingRepository;
    private final AccessScopeService accessScopeService;
    private final CostingItemRepository costingItemRepository;
    private final StyleService styleService;
    private final OrganizationRepository organizationRepository;
    private final CurrencyRepository currencyRepository;
    private final UserRepository userRepository;
    private final InquiryService inquiryService;
    private final ApprovalService approvalService;
    private final AuditService auditService;

    @Transactional
    public CostingResponse create(CostingRequest request) {
        return create(request, List.of());
    }

    private CostingResponse create(CostingRequest request, List<CostingItem> carryOverFrom) {
        var style = styleService.findInCurrentOrganization(request.styleId());
        if (!currencyRepository.existsById(request.currency())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
        }

        int nextVersion = costingRepository.findTopByStyleIdOrderByVersionNoDesc(request.styleId())
                .map(c -> c.getVersionNo() + 1)
                .orElse(1);

        Costing costing = new Costing();
        costing.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        costing.setStyle(style);
        costing.setVersionNo(nextVersion);
        costing.setCurrency(currencyRepository.getReferenceById(request.currency()));
        costing.setExchangeRate(request.exchangeRate());
        costing.setQuantity(request.quantity());
        costing.setTargetPrice(request.targetPrice());
        costing.setCreatedBy(userRepository.getReferenceById(currentUser().id()));
        if (request.inquiryId() != null) {
            costing.setInquiry(inquiryService.findInCurrentOrganization(request.inquiryId()));
        }
        costing = costingRepository.save(costing);

        applyItems(costing, request.items(), carryOverFrom);
        recalculate(costing);
        costing = costingRepository.saveAndFlush(costing);

        auditService.record("COSTING_CREATE", "Costing", costing.getId(), null, toResponse(costing), null);
        return toResponse(costing);
    }

    /** Document 9.1: editing a DRAFT costing's line items in place — blocked entirely
     * once APPROVED by the DB trigger even if this method were called by mistake. */
    @Transactional
    public CostingResponse updateDraft(Long costingId, CostingRequest request) {
        Costing costing = findInCurrentOrganization(costingId);
        if (costing.getStatus() != CostingStatus.DRAFT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Only a DRAFT costing can be edited; create a new version instead");
        }

        List<CostingItem> previousItems = new ArrayList<>();
        for (CostingItem old : costing.getItems()) {
            CostingItem copy = new CostingItem();
            copy.setId(old.getId());
            copy.setComponentType(old.getComponentType());
            copy.setDescription(old.getDescription());
            copy.setUnitCost(old.getUnitCost());
            previousItems.add(copy);
        }
        costingItemRepository.deleteAll(costing.getItems());
        costing.getItems().clear();
        costing.setExchangeRate(request.exchangeRate());
        costing.setQuantity(request.quantity());
        costing.setTargetPrice(request.targetPrice());
        applyItems(costing, request.items(), previousItems);
        recalculate(costing);
        costing = costingRepository.saveAndFlush(costing);

        auditService.record("COSTING_UPDATE_DRAFT", "Costing", costing.getId(), null, toResponse(costing), null);
        return toResponse(costing);
    }

    /** Document 10.2: submits the current DRAFT for approval via the shared ApprovalService. */
    @Transactional
    public CostingResponse submitForApproval(Long costingId) {
        Costing costing = findInCurrentOrganization(costingId);
        if (costing.getStatus() != CostingStatus.DRAFT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Only a DRAFT costing can be submitted for approval");
        }
        approvalService.submit(ApprovalTargetType.COSTING, costing.getId());
        return toResponse(costing);
    }

    /** Document 10.2: called after ApprovalService.decide() approves this costing's
     * latest round — flips DRAFT -> APPROVED, the one transition the DB trigger allows.
     * Runs automatically via onApprovalDecided(); the endpoint stays for older clients
     * and is idempotent. Re-reads the real approval round so it can't approve a costing
     * that was never approved through the engine. */
    @Transactional
    public CostingResponse markApproved(Long costingId) {
        Costing costing = findInCurrentOrganization(costingId);
        if (costing.getStatus() == CostingStatus.APPROVED) {
            return toResponse(costing);
        }
        if (approvalService.latestStatus(ApprovalTargetType.COSTING, costingId) != ApprovalStatus.APPROVED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Costing has no APPROVED approval round");
        }
        if (costing.getStatus() != CostingStatus.DRAFT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Costing is not in DRAFT status");
        }
        costing.setStatus(CostingStatus.APPROVED);
        costing.setApprovedAt(Instant.now());
        costing = costingRepository.save(costing);
        auditService.record("COSTING_APPROVED", "Costing", costing.getId(), CostingStatus.DRAFT, CostingStatus.APPROVED, null);
        return toResponse(costing);
    }

    @EventListener
    public void onApprovalDecided(ApprovalDecidedEvent event) {
        if (event.targetType() == ApprovalTargetType.COSTING && event.decision() == ApprovalStatus.APPROVED) {
            markApproved(event.targetId());
        }
    }

    /** Document 9.1: creates version N+1 referencing version N — the only way to
     * change an APPROVED costing's numbers. If the source was still DRAFT (never
     * approved), it's marked SUPERSEDED (an allowed transition, Doc 8.5); an
     * APPROVED source is left untouched forever (the trigger would block it anyway). */
    @Transactional
    public CostingResponse createRevision(Long sourceCostingId, CostingRequest request) {
        Costing source = findInCurrentOrganization(sourceCostingId);

        CostingResponse newVersion = create(request, source.getItems());
        Costing newCosting = costingRepository.getReferenceById(newVersion.id());
        newCosting.setSupersededFrom(source);
        costingRepository.save(newCosting);

        if (source.getStatus() == CostingStatus.DRAFT) {
            source.setStatus(CostingStatus.SUPERSEDED);
            costingRepository.save(source);
        }

        return toResponse(costingRepository.getReferenceById(newVersion.id()));
    }

    @Transactional(readOnly = true)
    public CostingResponse get(Long costingId) {
        return toResponse(findInCurrentOrganization(costingId));
    }

    @Transactional(readOnly = true)
    public Page<CostingResponse> list(Long styleId, Pageable pageable) {
        AccessScope scope = accessScopeService.current();
        return costingRepository.findVisible(currentUser().organizationId(), styleId, scope.unrestricted(), scope.buyerIdsParam(), scope.factoryIdsParam(), pageable).map(this::toResponse);
    }

    public Costing findInCurrentOrganization(Long costingId) {
        // Doc 5.3: tenant AND object-level scope — an out-of-scope record is a 404, same as a missing one.
        AccessScope scope = accessScopeService.current();
        return costingRepository.findVisibleById(costingId, currentUser().organizationId(), scope.unrestricted(), scope.buyerIdsParam(), scope.factoryIdsParam())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Costing not found"));
    }

    private void applyItems(Costing costing, List<CostingItemRequest> itemRequests, List<CostingItem> carryOverFrom) {
        List<CostingItem> unused = new ArrayList<>(carryOverFrom);
        for (CostingItemRequest itemRequest : itemRequests) {
            BigDecimal unitCost = itemRequest.unitCost() != null
                    ? itemRequest.unitCost()
                    : carriedOverUnitCost(itemRequest, unused);
            CostingItem item = new CostingItem();
            item.setCosting(costing);
            item.setComponentType(itemRequest.componentType());
            item.setDescription(itemRequest.description());
            item.setUnitCost(unitCost);
            item.setConsumption(itemRequest.consumption());
            item.setWastagePercent(itemRequest.wastagePercent());
            item.setTotalCost(computeItemTotal(unitCost, itemRequest));
            costing.getItems().add(item);
        }
    }

    /**
     * Doc 5.2 masking + 9.1 versioning: a role that never sees unit costs (Junior
     * Merchandiser) revises consumption/wastage only and sends unitCost=null; the
     * hidden value is carried over server-side from the source version's matching
     * line (by sourceItemId, else first unused line with the same component and
     * description) instead of being wiped or required.
     */
    private BigDecimal carriedOverUnitCost(CostingItemRequest request, List<CostingItem> unused) {
        CostingItem match = null;
        if (request.sourceItemId() != null) {
            match = unused.stream().filter(i -> request.sourceItemId().equals(i.getId())).findFirst().orElse(null);
        }
        if (match == null) {
            match = unused.stream()
                    .filter(i -> i.getComponentType() == request.componentType()
                            && java.util.Objects.equals(blankToNull(i.getDescription()), blankToNull(request.description())))
                    .findFirst().orElse(null);
        }
        if (match == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "unitCost is required for new cost line "
                    + request.componentType() + (request.description() != null ? " (" + request.description() + ")" : ""));
        }
        unused.remove(match);
        return match.getUnitCost();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    /** Document 9.1 formula: total_cost = unit_cost * consumption * (1 + wastage_percent/100). */
    private BigDecimal computeItemTotal(BigDecimal unitCost, CostingItemRequest request) {
        BigDecimal wastageMultiplier = BigDecimal.ONE.add(request.wastagePercent().divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));
        return unitCost.multiply(request.consumption()).multiply(wastageMultiplier).setScale(4, RoundingMode.HALF_UP);
    }

    /** Document 9.1: total cost and margin % recomputed server-side on every save — never client-supplied. */
    private void recalculate(Costing costing) {
        BigDecimal total = costing.getItems().stream()
                .map(CostingItem::getTotalCost)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        costing.setTotalCost(total);

        if (costing.getTargetPrice() != null && costing.getTargetPrice().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal margin = costing.getTargetPrice().subtract(total)
                    .divide(costing.getTargetPrice(), 6, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            costing.setMarginPercent(margin.setScale(3, RoundingMode.HALF_UP));
        } else {
            costing.setMarginPercent(null);
        }
    }

    /** Document 5.2/11.1: field-level masking — margin and the underlying cost figure
     * (which trivially reveals margin against a known target price) are hidden from
     * roles without COSTING_VIEW_MARGIN, in the mapper, server-side — never left to
     * the Flutter client to decide not to display. */
    private CostingResponse toResponse(Costing costing) {
        boolean canViewMargin = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("COSTING_VIEW_MARGIN"));

        List<CostingItemResponse> items = costing.getItems().stream()
                .map(i -> new CostingItemResponse(i.getId(), i.getComponentType(), i.getDescription(),
                        canViewMargin ? i.getUnitCost() : null, i.getConsumption(), i.getWastagePercent(),
                        canViewMargin ? i.getTotalCost() : null))
                .toList();

        return new CostingResponse(
                costing.getId(), costing.getStyle().getId(), costing.getInquiry() != null ? costing.getInquiry().getId() : null,
                costing.getVersionNo(), costing.getCurrency().getCode(), costing.getExchangeRate(), costing.getQuantity(),
                costing.getStatus(), costing.getTargetPrice(),
                canViewMargin ? costing.getTotalCost() : null,
                canViewMargin ? costing.getMarginPercent() : null,
                costing.getSupersededFrom() != null ? costing.getSupersededFrom().getId() : null,
                costing.getVersion(), items);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
