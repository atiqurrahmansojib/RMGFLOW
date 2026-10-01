package com.rmgflow.factory.repository;

import com.rmgflow.factory.entity.FactoryCertification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FactoryCertificationRepository extends JpaRepository<FactoryCertification, Long> {
    List<FactoryCertification> findByFactoryId(Long factoryId);
}
