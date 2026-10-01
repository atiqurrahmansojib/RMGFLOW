package com.rmgflow.ta.repository;

import com.rmgflow.ta.entity.TaMilestone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TaMilestoneRepository extends JpaRepository<TaMilestone, Long> {
    List<TaMilestone> findByOrderIdOrderBySequence(Long orderId);

    List<TaMilestone> findByDependsOnMilestoneId(Long milestoneId);

    Optional<TaMilestone> findByIdAndOrder_Organization_Id(Long id, Long organizationId);

    boolean existsByOrderId(Long orderId);
}
