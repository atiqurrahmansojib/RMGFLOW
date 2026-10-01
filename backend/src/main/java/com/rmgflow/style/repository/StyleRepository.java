package com.rmgflow.style.repository;

import com.rmgflow.style.entity.Style;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StyleRepository extends JpaRepository<Style, Long> {
    boolean existsByStyleNoIgnoreCase(String styleNo);

    Optional<Style> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Style> findByOrganizationIdAndActiveTrue(Long organizationId, Pageable pageable);

    Page<Style> findByOrganizationIdAndActiveTrueAndStyleNoContainingIgnoreCase(Long organizationId, String styleNoFragment, Pageable pageable);
}
