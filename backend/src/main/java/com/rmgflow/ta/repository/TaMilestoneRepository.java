package com.rmgflow.ta.repository;

import com.rmgflow.ta.entity.TaMilestone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TaMilestoneRepository extends JpaRepository<TaMilestone, Long> {
    List<TaMilestone> findByOrderIdOrderBySequence(Long orderId);

    List<TaMilestone> findByDependsOnMilestoneId(Long milestoneId);

    /** Document 13 A2: candidates for the overdue-notification scan — actual_date
     * not yet recorded means it hasn't been completed; status itself is NOT stored
     * authoritatively (Doc 9.5), so the scan re-derives overdue-ness from dates. */
    List<TaMilestone> findByActualDateIsNull();

    List<TaMilestone> findByResponsibleUser_IdAndActualDateIsNull(Long responsibleUserId);

    Optional<TaMilestone> findByIdAndOrder_Organization_Id(Long id, Long organizationId);

    boolean existsByOrderId(Long orderId);
}
