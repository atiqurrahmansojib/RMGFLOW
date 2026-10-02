package com.rmgflow.quality.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.quality.dto.InspectionRequest;
import com.rmgflow.quality.dto.InspectionResponse;
import com.rmgflow.quality.entity.Inspection;
import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import com.rmgflow.quality.repository.InspectionRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Document 9.7/9.8/10.6/10.9: inline/midline/final inspections. A FAILed FINAL
 * inspection blocks shipment creation (Doc 9.8) until a passing re-inspection
 * exists or an explicit override is recorded — Phase 10's ShipmentService queries
 * hasPassingFinalInspection() here rather than re-deriving the rule itself.
 */
@Service
@RequiredArgsConstructor
public class InspectionService {

    private final InspectionRepository inspectionRepository;
    private final OrderService orderService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public InspectionResponse create(Long orderId, InspectionRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);

        Inspection inspection = new Inspection();
        inspection.setOrder(order);
        inspection.setInspectionType(request.inspectionType());
        inspection.setInspectionDate(request.inspectionDate());
        inspection.setInspectedQty(request.inspectedQty());
        inspection.setAqlLevel(request.aqlLevel());
        inspection.setResult(request.result());
        inspection.setInspector(userRepository.getReferenceById(currentUser().id()));
        inspection = inspectionRepository.save(inspection);

        // Document 10.6: a FINAL FAIL is immediate (not batched) — surfaced the
        // moment it's recorded, not discovered later when someone tries to ship.
        if (request.inspectionType() == InspectionType.FINAL && request.result() == InspectionResult.FAIL) {
            auditService.record("QUALITY_FINAL_INSPECTION_FAILED", "Order", orderId, null, inspection.getId(), null);
        }

        auditService.record("INSPECTION_CREATE", "Inspection", inspection.getId(), null, toResponse(inspection), null);
        return toResponse(inspection);
    }

    @Transactional(readOnly = true)
    public List<InspectionResponse> list(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return inspectionRepository.findByOrderIdOrderByInspectionDateDesc(orderId).stream().map(this::toResponse).toList();
    }

    public Inspection findInCurrentOrganization(Long inspectionId) {
        return inspectionRepository.findByIdAndOrder_Organization_Id(inspectionId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Inspection not found"));
    }

    /** Document 9.7/9.8/10.9: the hard gate Phase 10's ShipmentService calls. */
    @Transactional(readOnly = true)
    public boolean hasPassingFinalInspection(Long orderId) {
        return inspectionRepository.existsByOrderIdAndInspectionTypeAndResult(orderId, InspectionType.FINAL, InspectionResult.PASS);
    }

    private InspectionResponse toResponse(Inspection inspection) {
        return new InspectionResponse(inspection.getId(), inspection.getOrder().getId(), inspection.getInspectionType(),
                inspection.getInspectionDate(), inspection.getInspectedQty(), inspection.getAqlLevel(), inspection.getResult(),
                inspection.getInspector() != null ? inspection.getInspector().getId() : null);
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
