package com.rmgflow.quality.repository;

import com.rmgflow.quality.entity.Inspection;
import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface InspectionRepository extends JpaRepository<Inspection, Long> {
    List<Inspection> findByOrderIdOrderByInspectionDateDesc(Long orderId);

    Optional<Inspection> findByIdAndOrder_Organization_Id(Long id, Long organizationId);

    /** Document 9.7/9.8/10.9: the exact check ShipmentService (Phase 10) runs —
     * does the order have at least one PASSing FINAL inspection. */
    boolean existsByOrderIdAndInspectionTypeAndResult(Long orderId, InspectionType inspectionType, InspectionResult result);
}
