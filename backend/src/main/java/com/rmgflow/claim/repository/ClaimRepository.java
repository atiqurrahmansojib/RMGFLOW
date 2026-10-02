package com.rmgflow.claim.repository;

import com.rmgflow.claim.entity.Claim;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ClaimRepository extends JpaRepository<Claim, Long> {
    List<Claim> findByOrderId(Long orderId);

    List<Claim> findByOrder_Organization_Id(Long organizationId);

    Optional<Claim> findByIdAndOrder_Organization_Id(Long id, Long organizationId);
}
