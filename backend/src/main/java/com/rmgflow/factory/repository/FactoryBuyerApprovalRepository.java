package com.rmgflow.factory.repository;

import com.rmgflow.factory.entity.FactoryBuyerApproval;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FactoryBuyerApprovalRepository extends JpaRepository<FactoryBuyerApproval, Long> {
    List<FactoryBuyerApproval> findByFactoryId(Long factoryId);

    Optional<FactoryBuyerApproval> findByFactoryIdAndBuyerId(Long factoryId, Long buyerId);

    /** Document 9.4: the exact check OrderService (Phase 6) runs before confirming an order. */
    boolean existsByFactoryIdAndBuyerIdAndStatus(Long factoryId, Long buyerId, FactoryBuyerApprovalStatus status);
}
