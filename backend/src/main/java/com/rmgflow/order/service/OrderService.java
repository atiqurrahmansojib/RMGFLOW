package com.rmgflow.order.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.service.FactoryBuyerApprovalService;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.masterdata.repository.CountryRepository;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.masterdata.repository.IncotermRepository;
import com.rmgflow.masterdata.repository.PaymentTermRepository;
import com.rmgflow.order.dto.*;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.entity.OrderItem;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.order.repository.OrderRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.security.scope.AccessScope;
import com.rmgflow.security.scope.AccessScopeService;
import com.rmgflow.style.entity.Style;
import com.rmgflow.style.service.StyleService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Document 8.6/9.4: order creation enforces the factory-buyer approval hard gate
 * (a real compliance requirement, not a convenience check) before anything is
 * persisted. Cancellation is gated by ORDER_CANCEL_APPROVE (Owner/GM only, Doc 5.2)
 * rather than routed through the generic ApprovalService — Doc 8.4's approval
 * target-type catalog is intentionally bounded (ADR-05), and this rule reduces to a
 * straightforward permission check with a mandatory recorded reason, not a
 * multi-round negotiation like costing/quotation/sample approval.
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final AccessScopeService accessScopeService;
    private final BuyerService buyerService;
    private final StyleService styleService;
    private final FactoryService factoryService;
    private final FactoryBuyerApprovalService factoryBuyerApprovalService;
    private final OrganizationRepository organizationRepository;
    private final CurrencyRepository currencyRepository;
    private final IncotermRepository incotermRepository;
    private final PaymentTermRepository paymentTermRepository;
    private final CountryRepository countryRepository;
    private final AuditService auditService;
    private final org.springframework.context.ApplicationEventPublisher eventPublisher;

    @Transactional
    public OrderResponse create(OrderRequest request) {
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());
        if (!currencyRepository.existsById(request.currency())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
        }

        Order order = new Order();
        order.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        order.setOrderNo("ORD-" + UUID.randomUUID());
        order.setBuyerPoNo(request.buyerPoNo());
        order.setBuyer(buyer);
        order.setOrderDate(request.orderDate());
        order.setExFactoryDate(request.exFactoryDate());
        order.setDeliveryDate(request.deliveryDate());
        order.setCurrency(currencyRepository.getReferenceById(request.currency()));
        applyOptionalHeaderFields(order, request);

        BigDecimal total = BigDecimal.ZERO;
        for (OrderItemRequest itemRequest : request.items()) {
            Style style = styleService.findInCurrentOrganization(itemRequest.styleId());
            Factory factory = factoryService.findInCurrentOrganization(itemRequest.factoryId());

            // Document 9.4 hard gate: a factory not APPROVED for this buyer cannot be
            // assigned to the order without an explicit, permission-gated, reasoned override.
            if (!factoryBuyerApprovalService.isApprovedForBuyer(factory.getId(), buyer.getId())) {
                requireFactoryOverride(request, factory, buyer);
            }

            OrderItem item = new OrderItem();
            item.setOrder(order);
            item.setStyle(style);
            item.setFactory(factory);
            item.setColor(itemRequest.color());
            item.setSize(itemRequest.size());
            item.setQuantity(itemRequest.quantity());
            item.setUnitPrice(itemRequest.unitPrice());
            order.getItems().add(item);
            total = total.add(itemRequest.unitPrice().multiply(BigDecimal.valueOf(itemRequest.quantity())));
        }
        order.setTotalValue(total);
        order = orderRepository.save(order);

        auditService.record("ORDER_CREATE", "Order", order.getId(), null, toResponse(order), null);
        eventPublisher.publishEvent(new OrderConfirmedEvent(order.getId(),
                order.getItems().isEmpty() ? null : order.getItems().get(0).getStyle().getId()));
        return toResponse(order);
    }

    @Transactional
    public void cancel(Long orderId, String reason) {
        if (!StringUtils.hasText(reason)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "A reason is required to cancel an order");
        }
        Order order = findInCurrentOrganization(orderId);
        if (order.getStatus() == OrderStatus.SHIPPED || order.getStatus() == OrderStatus.CLOSED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Cannot cancel an order that has already shipped or closed");
        }
        OrderStatus before = order.getStatus();
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);
        auditService.record("ORDER_CANCEL", "Order", order.getId(), before, OrderStatus.CANCELLED, reason);
    }

    @Transactional(readOnly = true)
    public OrderResponse get(Long orderId) {
        return toResponse(findInCurrentOrganization(orderId));
    }

    @Transactional(readOnly = true)
    public Page<OrderResponse> list(Long buyerId, OrderStatus status, Pageable pageable) {
        AccessScope scope = accessScopeService.current();
        return orderRepository.findVisible(currentUser().organizationId(), buyerId, status, scope.unrestricted(), scope.buyerIdsParam(), scope.factoryIdsParam(), pageable).map(this::toResponse);
    }

    public Order findInCurrentOrganization(Long orderId) {
        // Doc 5.3: tenant AND object-level scope — an out-of-scope record is a 404, same as a missing one.
        AccessScope scope = accessScopeService.current();
        return orderRepository.findVisibleById(orderId, currentUser().organizationId(), scope.unrestricted(), scope.buyerIdsParam(), scope.factoryIdsParam())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Order not found"));
    }

    private void requireFactoryOverride(OrderRequest request, Factory factory, Buyer buyer) {
        boolean hasOverridePermission = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ORDER_FACTORY_OVERRIDE"));
        if (!request.overrideFactoryApproval() || !hasOverridePermission || !StringUtils.hasText(request.overrideReason())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Factory " + factory.getCode() + " is not approved for buyer " + buyer.getCode()
                            + "; override requires ORDER_FACTORY_OVERRIDE permission and a reason");
        }
        auditService.record("ORDER_FACTORY_APPROVAL_OVERRIDE", "Factory", factory.getId(), null, buyer.getId(), request.overrideReason());
    }

    private void applyOptionalHeaderFields(Order order, OrderRequest request) {
        if (request.incoterm() != null) {
            if (!incotermRepository.existsById(request.incoterm())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Incoterm not found");
            }
            order.setIncoterm(incotermRepository.getReferenceById(request.incoterm()));
        }
        if (request.paymentTermsId() != null) {
            if (!paymentTermRepository.existsById(request.paymentTermsId())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Payment term not found");
            }
            order.setPaymentTerms(paymentTermRepository.getReferenceById(request.paymentTermsId()));
        }
        if (request.destinationCountry() != null) {
            if (!countryRepository.existsById(request.destinationCountry())) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Country not found");
            }
            order.setDestinationCountry(countryRepository.getReferenceById(request.destinationCountry()));
        }
    }

    OrderResponse toResponse(Order order) {
        List<OrderItemResponse> items = order.getItems().stream()
                .map(i -> new OrderItemResponse(i.getId(), i.getStyle().getId(), i.getFactory().getId(), i.getColor(), i.getSize(), i.getQuantity(), i.getUnitPrice()))
                .toList();
        return new OrderResponse(order.getId(), order.getOrderNo(), order.getBuyerPoNo(), order.getBuyer().getId(),
                order.getQuotation() != null ? order.getQuotation().getId() : null, order.getStatus(),
                order.getOrderDate(), order.getExFactoryDate(), order.getDeliveryDate(),
                order.getIncoterm() != null ? order.getIncoterm().getCode() : null,
                order.getPaymentTerms() != null ? order.getPaymentTerms().getId() : null,
                order.getDestinationCountry() != null ? order.getDestinationCountry().getCode() : null,
                order.getTotalValue(), order.getCurrency().getCode(), order.getVersion(), items);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
