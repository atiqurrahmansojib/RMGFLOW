package com.rmgflow.ta.repository;

import com.rmgflow.ta.entity.TaTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TaTemplateRepository extends JpaRepository<TaTemplate, Long> {
    List<TaTemplate> findByOrganizationId(Long organizationId);

    Optional<TaTemplate> findByIdAndOrganizationId(Long id, Long organizationId);

    Optional<TaTemplate> findFirstByOrganizationIdAndStyleId(Long organizationId, Long styleId);

    Optional<TaTemplate> findFirstByOrganizationIdAndBuyerIdAndStyleIsNull(Long organizationId, Long buyerId);

    Optional<TaTemplate> findFirstByOrganizationIdAndIsDefaultTrue(Long organizationId);
}
