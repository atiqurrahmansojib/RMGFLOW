package com.rmgflow.costing.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.costing.entity.Costing;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CostingRepository extends JpaRepository<Costing, Long> {
    Optional<Costing> findByIdAndOrganizationId(Long id, Long organizationId);

    Optional<Costing> findTopByStyleIdOrderByVersionNoDesc(Long styleId);

    Page<Costing> findByOrganizationIdAndStyleId(Long organizationId, Long styleId, Pageable pageable);

    Page<Costing> findByOrganizationId(Long organizationId, Pageable pageable);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select c from Costing c where c.organization.id = :orgId and (:styleId is null or c.style.id = :styleId)"
            + " and (:all = true or c.style.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = c.style and i.factory.id in :factoryIds))")
    Page<Costing> findVisible(@Param("orgId") Long orgId, @Param("styleId") Long styleId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select c from Costing c where c.id = :id and c.organization.id = :orgId"
            + " and (:all = true or c.style.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = c.style and i.factory.id in :factoryIds))")
    Optional<Costing> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}
