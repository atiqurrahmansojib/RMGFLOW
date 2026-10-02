package com.rmgflow.production.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.entity.OrderItem;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.production.dto.ProductionProgressResponse;
import com.rmgflow.production.dto.ProductionUpdateRequest;
import com.rmgflow.production.dto.ProductionUpdateResponse;
import com.rmgflow.production.entity.ProductionUpdate;
import com.rmgflow.production.repository.ProductionUpdateRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Document 9.6: cumulative totals are ALWAYS a SUM over production_updates — this
 * service never reads or writes a running-total field, because none exists (Doc
 * 8.8). Packing is the one hard gate: cumulative packed quantity must never exceed
 * the order's total ordered quantity (Doc 9.8 depends on this being trustworthy —
 * a shipment's quantity validation only means something if packing itself was
 * never allowed to overstate what was produced). Cutting/sewing/finishing
 * exceeding order quantity is only a soft signal (real production sometimes runs
 * slightly over to cover rejections), not blocked.
 */
@Service
@RequiredArgsConstructor
public class ProductionUpdateService {

    private final ProductionUpdateRepository productionUpdateRepository;
    private final OrderService orderService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    /** Upserts the single row for (order, date) — a same-day correction overwrites
     * itself rather than creating a second row, matching how a daily tally is
     * actually used operationally (Doc 9.6 does not treat this as a financial/
     * approval record requiring append-only history, unlike costing/quotation). */
    @Transactional
    public ProductionUpdateResponse recordDailyUpdate(Long orderId, ProductionUpdateRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        int orderQuantity = totalOrderQuantity(order);

        ProductionUpdate update = productionUpdateRepository.findByOrderIdAndUpdateDate(orderId, request.updateDate())
                .orElseGet(ProductionUpdate::new);
        boolean isNew = update.getId() == null;

        int existingPacking = sumExcludingDate(orderId, request.updateDate(), ProductionUpdate::getPackingQty);
        int newCumulativePacking = existingPacking + request.packingQty();
        if (newCumulativePacking > orderQuantity) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Cumulative packed quantity (" + newCumulativePacking + ") would exceed the order quantity (" + orderQuantity + ")");
        }

        update.setOrder(order);
        update.setUpdateDate(request.updateDate());
        update.setCuttingQty(request.cuttingQty());
        update.setSewingQty(request.sewingQty());
        update.setFinishingQty(request.finishingQty());
        update.setPackingQty(request.packingQty());
        update.setRejectionQty(request.rejectionQty());
        update.setAlterationQty(request.alterationQty());
        if (isNew) {
            update.setEnteredBy(userRepository.getReferenceById(currentUser().id()));
        }
        update = productionUpdateRepository.save(update);

        auditService.record(isNew ? "PRODUCTION_UPDATE_CREATE" : "PRODUCTION_UPDATE_CORRECT", "Order", orderId, null, toResponse(update), null);
        return toResponse(update);
    }

    @Transactional(readOnly = true)
    public ProductionProgressResponse progress(Long orderId) {
        Order order = orderService.findInCurrentOrganization(orderId);
        List<ProductionUpdate> updates = productionUpdateRepository.findByOrderIdOrderByUpdateDate(orderId);
        int orderQuantity = totalOrderQuantity(order);

        int cumulativeCutting = updates.stream().mapToInt(ProductionUpdate::getCuttingQty).sum();
        int cumulativeSewing = updates.stream().mapToInt(ProductionUpdate::getSewingQty).sum();
        int cumulativeFinishing = updates.stream().mapToInt(ProductionUpdate::getFinishingQty).sum();
        int cumulativePacking = updates.stream().mapToInt(ProductionUpdate::getPackingQty).sum();
        int cumulativeRejection = updates.stream().mapToInt(ProductionUpdate::getRejectionQty).sum();
        int cumulativeAlteration = updates.stream().mapToInt(ProductionUpdate::getAlterationQty).sum();
        double packingProgressPercent = orderQuantity == 0 ? 0 : (cumulativePacking * 100.0) / orderQuantity;

        return new ProductionProgressResponse(orderId, orderQuantity, cumulativeCutting, cumulativeSewing,
                cumulativeFinishing, cumulativePacking, cumulativeRejection, cumulativeAlteration,
                packingProgressPercent, updates.stream().map(this::toResponse).toList());
    }

    private int sumExcludingDate(Long orderId, java.time.LocalDate excludedDate, java.util.function.ToIntFunction<ProductionUpdate> extractor) {
        return productionUpdateRepository.findByOrderIdOrderByUpdateDate(orderId).stream()
                .filter(u -> !u.getUpdateDate().equals(excludedDate))
                .mapToInt(extractor)
                .sum();
    }

    private int totalOrderQuantity(Order order) {
        return order.getItems().stream().mapToInt(OrderItem::getQuantity).sum();
    }

    private ProductionUpdateResponse toResponse(ProductionUpdate update) {
        return new ProductionUpdateResponse(update.getId(), update.getOrder().getId(), update.getUpdateDate(),
                update.getCuttingQty(), update.getSewingQty(), update.getFinishingQty(), update.getPackingQty(),
                update.getRejectionQty(), update.getAlterationQty());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
