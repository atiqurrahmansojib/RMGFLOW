package com.rmgflow.factory.repository;

import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.PartnerType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FactoryRepository extends JpaRepository<Factory, Long> {
    boolean existsByCodeIgnoreCase(String code);

    Page<Factory> findByActiveTrueAndPartnerType(PartnerType partnerType, Pageable pageable);

    Page<Factory> findByActiveTrue(Pageable pageable);
}
