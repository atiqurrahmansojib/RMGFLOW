package com.rmgflow.financial.repository;

import com.rmgflow.financial.entity.OrderFinancials;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OrderFinancialsRepository extends JpaRepository<OrderFinancials, Long> {
    Optional<OrderFinancials> findByOrderId(Long orderId);

    Optional<OrderFinancials> findByIdAndOrder_Organization_Id(Long id, Long organizationId);
}
