package com.rmgflow.shipment.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.entity.OrderItem;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.order.repository.OrderRepository;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.quality.service.InspectionService;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.shipment.dto.ShipmentRequest;
import com.rmgflow.shipment.dto.ShipmentResponse;
import com.rmgflow.shipment.entity.Shipment;
import com.rmgflow.shipment.entity.ShipmentStatus;
import com.rmgflow.shipment.repository.ShipmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.UUID;

/**
 * Document 9.8/10.7/10.9: the three gates enforced here, in order:
 * 1. A passing FINAL inspection must exist (Doc 9.7/Phase 9's hasPassingFinalInspection),
 *    unless SHIPMENT_QUALITY_OVERRIDE is held and a reason is given.
 * 2. Cumulative quantity_shipped across ALL of the order's shipments must never
 *    exceed the order's total quantity — hard-blocked, NO override, ever (Doc 9.11 #5).
 * 3. A partial shipment (less than the remaining quantity) requires
 *    SHIPMENT_PARTIAL_AUTHORIZE, recorded as authorized_by.
 * On completion (cumulative shipped == order quantity), the order's status
 * advances PARTIALLY_SHIPPED -> SHIPPED.
 */
@Service
@RequiredArgsConstructor
public class ShipmentService {

    private final ShipmentRepository shipmentRepository;
    private final OrderService orderService;
    private final OrderRepository orderRepository;
    private final InspectionService inspectionService;
    private final FactoryService factoryService;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public ShipmentResponse create(Long orderId, ShipmentRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        if (order.getStatus() == OrderStatus.CANCELLED || order.getStatus() == OrderStatus.CLOSED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Cannot ship a " + order.getStatus() + " order");
        }

        requireQualityGate(orderId, request);

        int orderQuantity = order.getItems().stream().mapToInt(OrderItem::getQuantity).sum();
        int alreadyShipped = shipmentRepository.sumQuantityShippedByOrderId(orderId);
        int remaining = orderQuantity - alreadyShipped;

        // Document 9.11 #5: hard block, never exceed the order's total quantity — no override exists for this one.
        if (request.quantityShipped() > remaining) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Shipment quantity (" + request.quantityShipped() + ") exceeds the remaining order quantity (" + remaining + ")");
        }
        boolean isPartial = request.quantityShipped() < remaining;
        if (isPartial) {
            requirePartialAuthorization();
        }

        Shipment shipment = new Shipment();
        shipment.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        shipment.setShipmentNo("SHP-" + UUID.randomUUID());
        shipment.setOrder(order);
        shipment.setShipmentDate(request.shipmentDate());
        shipment.setEtd(request.etd());
        shipment.setEta(request.eta());
        shipment.setQuantityShipped(request.quantityShipped());
        shipment.setCartons(request.cartons());
        shipment.setGrossWeight(request.grossWeight());
        shipment.setNetWeight(request.netWeight());
        shipment.setVolumeCbm(request.volumeCbm());
        shipment.setPortOfLoading(request.portOfLoading());
        shipment.setPortOfDischarge(request.portOfDischarge());
        shipment.setForwarder(request.forwarderId() != null ? factoryService.findInCurrentOrganization(request.forwarderId()) : null);
        shipment.setShippingLine(request.shippingLine());
        shipment.setContainerNo(request.containerNo());
        shipment.setBlAwbNo(request.blAwbNo());
        shipment.setPartial(isPartial);
        if (isPartial) {
            shipment.setAuthorizedBy(userRepository.getReferenceById(currentUser().id()));
        }
        shipment = shipmentRepository.save(shipment);

        // Document 10.7: order status advances as cumulative shipped quantity changes.
        int totalShippedNow = alreadyShipped + request.quantityShipped();
        order.setStatus(totalShippedNow >= orderQuantity ? OrderStatus.SHIPPED : OrderStatus.PARTIALLY_SHIPPED);
        orderRepository.save(order);

        auditService.record("SHIPMENT_CREATE", "Order", orderId, null, toResponse(shipment), request.overrideReason());
        return toResponse(shipment);
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> list(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return shipmentRepository.findByOrderId(orderId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public ShipmentResponse updateStatus(Long shipmentId, ShipmentStatus status) {
        Shipment shipment = findInCurrentOrganization(shipmentId);
        ShipmentStatus before = shipment.getStatus();
        shipment.setStatus(status);
        shipment = shipmentRepository.save(shipment);
        auditService.record("SHIPMENT_STATUS_CHANGE", "Shipment", shipment.getId(), before, status, null);
        return toResponse(shipment);
    }

    public Shipment findInCurrentOrganization(Long shipmentId) {
        return shipmentRepository.findByIdAndOrder_Organization_Id(shipmentId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Shipment not found"));
    }

    private void requireQualityGate(Long orderId, ShipmentRequest request) {
        if (inspectionService.hasPassingFinalInspection(orderId)) {
            return;
        }
        boolean hasOverridePermission = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("SHIPMENT_QUALITY_OVERRIDE"));
        if (!request.overrideQualityGate() || !hasOverridePermission || !StringUtils.hasText(request.overrideReason())) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Order has no passing FINAL inspection; override requires SHIPMENT_QUALITY_OVERRIDE permission and a reason");
        }
        auditService.record("SHIPMENT_QUALITY_GATE_OVERRIDE", "Order", orderId, null, null, request.overrideReason());
    }

    private void requirePartialAuthorization() {
        boolean hasPermission = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("SHIPMENT_PARTIAL_AUTHORIZE"));
        if (!hasPermission) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Partial shipment requires SHIPMENT_PARTIAL_AUTHORIZE permission");
        }
    }

    private ShipmentResponse toResponse(Shipment shipment) {
        return new ShipmentResponse(shipment.getId(), shipment.getShipmentNo(), shipment.getOrder().getId(),
                shipment.getShipmentDate(), shipment.getEtd(), shipment.getEta(), shipment.getQuantityShipped(),
                shipment.getCartons(), shipment.getGrossWeight(), shipment.getNetWeight(), shipment.getVolumeCbm(),
                shipment.getPortOfLoading(), shipment.getPortOfDischarge(),
                shipment.getForwarder() != null ? shipment.getForwarder().getId() : null, shipment.getShippingLine(),
                shipment.getContainerNo(), shipment.getBlAwbNo(), shipment.getStatus(), shipment.isPartial(),
                shipment.getAuthorizedBy() != null ? shipment.getAuthorizedBy().getId() : null);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
