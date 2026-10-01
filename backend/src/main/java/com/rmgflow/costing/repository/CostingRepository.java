package com.rmgflow.costing.repository;

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
}
