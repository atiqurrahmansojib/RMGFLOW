package com.rmgflow.order.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

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

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select o from Order o where o.organization.id = :orgId and (:buyerId is null or o.buyer.id = :buyerId) and (:status is null or o.status = :status)"
            + " and (:all = true or o.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.order = o and i.factory.id in :factoryIds))")
    Page<Order> findVisible(@Param("orgId") Long orgId, @Param("buyerId") Long buyerId, @Param("status") OrderStatus status, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select o from Order o where o.id = :id and o.organization.id = :orgId"
            + " and (:all = true or o.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.order = o and i.factory.id in :factoryIds))")
    Optional<Order> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}
