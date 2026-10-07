package com.rmgflow.factory.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.PartnerType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FactoryRepository extends JpaRepository<Factory, Long> {
    boolean existsByCodeIgnoreCase(String code);

    /** Security review fix: scope every read/write to the caller's organization (same
     * IDOR rationale as BuyerRepository's equivalent methods). */
    Page<Factory> findByOrganizationIdAndActiveTrueAndPartnerType(Long organizationId, PartnerType partnerType, Pageable pageable);

    Page<Factory> findByOrganizationIdAndActiveTrue(Long organizationId, Pageable pageable);

    Optional<Factory> findByIdAndOrganizationId(Long id, Long organizationId);

    /** Doc 5.3 object-level scope: org + (open directory OR assigned factory). */
    @Query("select f from Factory f where f.organization.id = :orgId and f.active = true and (:partnerType is null or f.partnerType = :partnerType)"
            + " and (:all = true or f.id in :factoryIds)")
    Page<Factory> findVisible(@Param("orgId") Long orgId, @Param("partnerType") PartnerType partnerType, @Param("all") boolean all, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select f from Factory f where f.id = :id and f.organization.id = :orgId"
            + " and (:all = true or f.id in :factoryIds)")
    Optional<Factory> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("factoryIds") Collection<Long> factoryIds);
}
