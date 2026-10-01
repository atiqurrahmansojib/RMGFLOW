package com.rmgflow.buyer.repository;

import com.rmgflow.buyer.entity.BuyerContact;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BuyerContactRepository extends JpaRepository<BuyerContact, Long> {
    List<BuyerContact> findByBuyerId(Long buyerId);

    boolean existsByBuyerIdAndPrimaryTrue(Long buyerId);
}
