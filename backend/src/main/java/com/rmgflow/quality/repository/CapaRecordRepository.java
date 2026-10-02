package com.rmgflow.quality.repository;

import com.rmgflow.quality.entity.CapaRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CapaRecordRepository extends JpaRepository<CapaRecord, Long> {
    List<CapaRecord> findByDefectId(Long defectId);

    List<CapaRecord> findByInspectionId(Long inspectionId);
}
