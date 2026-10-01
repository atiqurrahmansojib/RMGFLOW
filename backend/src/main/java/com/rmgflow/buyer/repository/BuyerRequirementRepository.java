package com.rmgflow.buyer.repository;

import com.rmgflow.buyer.entity.BuyerRequirement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BuyerRequirementRepository extends JpaRepository<BuyerRequirement, Long> {
    List<BuyerRequirement> findByBuyerId(Long buyerId);
}
