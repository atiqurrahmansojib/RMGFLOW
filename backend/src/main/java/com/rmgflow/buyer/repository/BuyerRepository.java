package com.rmgflow.buyer.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.buyer.entity.Buyer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface BuyerRepository extends JpaRepository<Buyer, Long> {
    boolean existsByCodeIgnoreCase(String code);

    /** Security review fix: every read/write must be scoped to the caller's organization
     * (organizations table is multi-tenant-ready per ADR-10, so cross-org row access via
     * a guessable id is a real IDOR, not a theoretical one, even in a "single org for now" deployment). */
    Page<Buyer> findByOrganizationIdAndActiveTrueAndNameContainingIgnoreCase(Long organizationId, String nameFragment, Pageable pageable);

    Page<Buyer> findByOrganizationIdAndActiveTrue(Long organizationId, Pageable pageable);

    Optional<Buyer> findByIdAndOrganizationId(Long id, Long organizationId);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select b from Buyer b where b.organization.id = :orgId and b.active = true and lower(b.name) like lower(concat('%', :search, '%'))"
            + " and (:all = true or b.id in :buyerIds or exists (select i.id from OrderItem i where i.order.buyer = b and i.factory.id in :factoryIds))")
    Page<Buyer> findVisible(@Param("orgId") Long orgId, @Param("search") String search, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select b from Buyer b where b.id = :id and b.organization.id = :orgId"
            + " and (:all = true or b.id in :buyerIds or exists (select i.id from OrderItem i where i.order.buyer = b and i.factory.id in :factoryIds))")
    Optional<Buyer> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}
