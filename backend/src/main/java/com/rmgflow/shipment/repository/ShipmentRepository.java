package com.rmgflow.shipment.repository;

import com.rmgflow.shipment.entity.Shipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ShipmentRepository extends JpaRepository<Shipment, Long> {
    List<Shipment> findByOrderId(Long orderId);

    Optional<Shipment> findByIdAndOrder_Organization_Id(Long id, Long organizationId);

    @Query("select coalesce(sum(s.quantityShipped), 0) from Shipment s where s.order.id = :orderId")
    int sumQuantityShippedByOrderId(@Param("orderId") Long orderId);
}
