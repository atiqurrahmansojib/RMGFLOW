package com.rmgflow.quality.repository;

import com.rmgflow.quality.entity.Defect;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DefectRepository extends JpaRepository<Defect, Long> {
    List<Defect> findByInspectionId(Long inspectionId);
}
