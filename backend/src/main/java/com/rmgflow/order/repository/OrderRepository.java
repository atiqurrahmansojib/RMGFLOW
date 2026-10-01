package com.rmgflow.order.repository;

import com.rmgflow.order.entity.Order;
import com.rmgflow.order.entity.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    boolean existsByOrderNoIgnoreCase(String orderNo);

    Optional<Order> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Order> findByOrganizationIdAndBuyerId(Long organizationId, Long buyerId, Pageable pageable);

    Page<Order> findByOrganizationIdAndStatus(Long organizationId, OrderStatus status, Pageable pageable);

    Page<Order> findByOrganizationId(Long organizationId, Pageable pageable);
}
