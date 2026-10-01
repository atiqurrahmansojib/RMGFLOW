package com.rmgflow.costing.repository;

import com.rmgflow.costing.entity.CostingItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CostingItemRepository extends JpaRepository<CostingItem, Long> {
    List<CostingItem> findByCostingId(Long costingId);
}
