package com.rmgflow.order.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.dto.OrderAmendmentRequest;
import com.rmgflow.order.dto.OrderAmendmentResponse;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.entity.OrderAmendment;
import com.rmgflow.order.entity.OrderAmendmentStatus;
import com.rmgflow.order.repository.OrderAmendmentRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Document 9.4: order amendments are append-only (FR-72) and the write of this row
 * plus the update of the order's live field happen in ONE transaction (decide()) —
 * never two separate calls that could leave the amendment log and the order's
 * actual value out of sync if one failed. Senior Merchandiser can only request();
 * only a holder of ORDER_AMEND_APPROVE (checked at the controller) can decide().
 *
 * Deliberately supports only a small, explicit set of amendable fields
 * (exFactoryDate, deliveryDate) rather than a generic reflective "set any field"
 * API — quantity/price amendments carry additional business rules (Doc 9.4's
 * "quantity reduction below already-shipped quantity is blocked") that belong in
 * Phase 7+ once shipment data exists to check against, not bolted on here early.
 */
@Service
@RequiredArgsConstructor
public class OrderAmendmentService {

    private final OrderAmendmentRepository orderAmendmentRepository;
    private final OrderService orderService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public OrderAmendmentResponse request(Long orderId, OrderAmendmentRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        String oldValue = readCurrentFieldValue(order, request.fieldChanged());

        int nextAmendmentNo = orderAmendmentRepository.findTopByOrderIdOrderByAmendmentNoDesc(orderId)
                .map(a -> a.getAmendmentNo() + 1)
                .orElse(1);

        OrderAmendment amendment = new OrderAmendment();
        amendment.setOrder(order);
        amendment.setAmendmentNo(nextAmendmentNo);
        amendment.setFieldChanged(request.fieldChanged());
        amendment.setOldValue(oldValue);
        amendment.setNewValue(request.newValue());
        amendment.setReason(request.reason());
        amendment.setRequestedBy(userRepository.getReferenceById(currentUser().id()));
        amendment = orderAmendmentRepository.save(amendment);

        auditService.record("ORDER_AMENDMENT_REQUEST", "Order", orderId, null, toResponse(amendment), request.reason());
        return toResponse(amendment);
    }

    /** Document 9.4: the ONLY code path that mutates an order's commercial field
     * post-confirmation — always paired with writing this decision in the same
     * transaction, never a silent direct field edit. */
    @Transactional
    public OrderAmendmentResponse decide(Long orderId, Long amendmentId, boolean approve) {
        orderService.findInCurrentOrganization(orderId);
        OrderAmendment amendment = orderAmendmentRepository.findById(amendmentId)
                .filter(a -> a.getOrder().getId().equals(orderId))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Amendment not found"));

        if (amendment.getStatus() != OrderAmendmentStatus.REQUESTED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "This amendment has already been " + amendment.getStatus());
        }

        amendment.setStatus(approve ? OrderAmendmentStatus.APPROVED : OrderAmendmentStatus.REJECTED);
        amendment.setApprovedBy(userRepository.getReferenceById(currentUser().id()));
        amendment.setDecidedAt(Instant.now());

        if (approve) {
            applyFieldChange(amendment.getOrder(), amendment.getFieldChanged(), amendment.getNewValue());
        }
        amendment = orderAmendmentRepository.save(amendment);

        auditService.record("ORDER_AMENDMENT_DECIDE", "Order", orderId, OrderAmendmentStatus.REQUESTED, amendment.getStatus(), null);
        return toResponse(amendment);
    }

    @Transactional(readOnly = true)
    public List<OrderAmendmentResponse> list(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return orderAmendmentRepository.findByOrderIdOrderByAmendmentNoDesc(orderId).stream().map(this::toResponse).toList();
    }

    private String readCurrentFieldValue(Order order, String fieldChanged) {
        return switch (fieldChanged) {
            case "exFactoryDate" -> String.valueOf(order.getExFactoryDate());
            case "deliveryDate" -> String.valueOf(order.getDeliveryDate());
            default -> throw new ApiException(HttpStatus.BAD_REQUEST, "Unsupported amendment field: " + fieldChanged);
        };
    }

    private void applyFieldChange(Order order, String fieldChanged, String newValue) {
        switch (fieldChanged) {
            case "exFactoryDate" -> order.setExFactoryDate(LocalDate.parse(newValue));
            case "deliveryDate" -> order.setDeliveryDate(LocalDate.parse(newValue));
            default -> throw new ApiException(HttpStatus.BAD_REQUEST, "Unsupported amendment field: " + fieldChanged);
        }
    }

    private OrderAmendmentResponse toResponse(OrderAmendment amendment) {
        return new OrderAmendmentResponse(amendment.getId(), amendment.getOrder().getId(), amendment.getAmendmentNo(),
                amendment.getFieldChanged(), amendment.getOldValue(), amendment.getNewValue(), amendment.getReason(),
                amendment.getRequestedBy() != null ? amendment.getRequestedBy().getId() : null,
                amendment.getApprovedBy() != null ? amendment.getApprovedBy().getId() : null,
                amendment.getStatus(), amendment.getCreatedAt());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
