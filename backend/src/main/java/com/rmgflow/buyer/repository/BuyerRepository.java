package com.rmgflow.buyer.repository;

import com.rmgflow.buyer.entity.Buyer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BuyerRepository extends JpaRepository<Buyer, Long> {
    boolean existsByCodeIgnoreCase(String code);

    Page<Buyer> findByActiveTrueAndNameContainingIgnoreCase(String nameFragment, Pageable pageable);

    Page<Buyer> findByActiveTrue(Pageable pageable);
}
