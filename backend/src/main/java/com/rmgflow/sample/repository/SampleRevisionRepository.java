package com.rmgflow.sample.repository;

import com.rmgflow.sample.entity.SampleRevision;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SampleRevisionRepository extends JpaRepository<SampleRevision, Long> {
    List<SampleRevision> findBySampleIdOrderByRevisionNoDesc(Long sampleId);

    Optional<SampleRevision> findTopBySampleIdOrderByRevisionNoDesc(Long sampleId);
}
