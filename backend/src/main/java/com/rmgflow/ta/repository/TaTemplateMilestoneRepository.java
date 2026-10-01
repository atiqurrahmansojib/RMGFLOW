package com.rmgflow.ta.repository;

import com.rmgflow.ta.entity.TaTemplateMilestone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TaTemplateMilestoneRepository extends JpaRepository<TaTemplateMilestone, Long> {
    List<TaTemplateMilestone> findByTemplateIdOrderBySequence(Long templateId);
}
