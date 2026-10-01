package com.rmgflow.buyer.repository;

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
}
