package com.rmgflow.factory.repository;

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
}
