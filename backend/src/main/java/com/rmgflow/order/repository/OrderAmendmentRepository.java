package com.rmgflow.order.repository;

import com.rmgflow.order.entity.OrderAmendment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OrderAmendmentRepository extends JpaRepository<OrderAmendment, Long> {
    List<OrderAmendment> findByOrderIdOrderByAmendmentNoDesc(Long orderId);

    Optional<OrderAmendment> findTopByOrderIdOrderByAmendmentNoDesc(Long orderId);
}
