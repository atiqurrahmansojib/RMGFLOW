package com.rmgflow.factory.repository;

import com.rmgflow.factory.entity.FactoryContact;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FactoryContactRepository extends JpaRepository<FactoryContact, Long> {
    List<FactoryContact> findByFactoryId(Long factoryId);

    boolean existsByFactoryIdAndPrimaryTrue(Long factoryId);
}
