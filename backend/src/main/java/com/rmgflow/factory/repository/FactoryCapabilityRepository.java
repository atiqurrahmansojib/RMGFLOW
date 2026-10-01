package com.rmgflow.factory.repository;

import com.rmgflow.factory.entity.FactoryCapability;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FactoryCapabilityRepository extends JpaRepository<FactoryCapability, Long> {
    List<FactoryCapability> findByFactoryId(Long factoryId);

    boolean existsByFactoryIdAndProductCategoryIgnoreCase(Long factoryId, String productCategory);
}
