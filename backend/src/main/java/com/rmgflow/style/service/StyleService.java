package com.rmgflow.style.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.masterdata.repository.SeasonRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.style.entity.Style;
import com.rmgflow.style.repository.StyleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/** Document 21 P3-T4: style master CRUD. Spec data itself lives in StyleRevision
 * (append-only, see StyleRevisionService) — this service only owns the master record. */
@Service
@RequiredArgsConstructor
public class StyleService {

    private final StyleRepository styleRepository;
    private final BuyerService buyerService;
    private final OrganizationRepository organizationRepository;
    private final SeasonRepository seasonRepository;
    private final AuditService auditService;

    @Transactional
    public StyleResponse create(StyleRequest request) {
        if (styleRepository.existsByStyleNoIgnoreCase(request.styleNo())) {
            throw new ApiException(HttpStatus.CONFLICT, "A style with this number already exists");
        }
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());

        Style style = new Style();
        style.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        style.setStyleNo(request.styleNo());
        style.setBuyer(buyer);
        applyRequest(style, request);
        style = styleRepository.save(style);

        auditService.record("STYLE_CREATE", "Style", style.getId(), null, toResponse(style), null);
        return toResponse(style);
    }

    @Transactional
    public StyleResponse update(Long styleId, StyleRequest request) {
        Style style = findInCurrentOrganization(styleId);
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());

        StyleResponse before = toResponse(style);
        style.setBuyer(buyer);
        applyRequest(style, request);
        style = styleRepository.save(style);

        auditService.record("STYLE_UPDATE", "Style", style.getId(), before, toResponse(style), null);
        return toResponse(style);
    }

    @Transactional(readOnly = true)
    public StyleResponse get(Long styleId) {
        return toResponse(findInCurrentOrganization(styleId));
    }

    @Transactional(readOnly = true)
    public Page<StyleResponse> list(String search, Pageable pageable) {
        Long organizationId = currentUser().organizationId();
        Page<Style> page = StringUtils.hasText(search)
                ? styleRepository.findByOrganizationIdAndActiveTrueAndStyleNoContainingIgnoreCase(organizationId, search, pageable)
                : styleRepository.findByOrganizationIdAndActiveTrue(organizationId, pageable);
        return page.map(this::toResponse);
    }

    public Style findInCurrentOrganization(Long styleId) {
        return styleRepository.findByIdAndOrganizationId(styleId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Style not found"));
    }

    private void applyRequest(Style style, StyleRequest request) {
        style.setBuyerStyleNo(request.buyerStyleNo());
        style.setProductCategory(request.productCategory());
        if (request.seasonId() != null) {
            if (!seasonRepository.existsById(request.seasonId())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Season not found");
            }
            style.setSeason(seasonRepository.getReferenceById(request.seasonId()));
        } else {
            style.setSeason(null);
        }
        style.setGender(request.gender());
        style.setDescription(request.description());
    }

    private StyleResponse toResponse(Style style) {
        return new StyleResponse(
                style.getId(), style.getStyleNo(), style.getBuyer().getId(), style.getBuyerStyleNo(),
                style.getProductCategory(), style.getSeason() != null ? style.getSeason().getId() : null,
                style.getGender(), style.getDescription(),
                style.getCurrentRevision() != null ? style.getCurrentRevision().getId() : null,
                style.isActive());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
