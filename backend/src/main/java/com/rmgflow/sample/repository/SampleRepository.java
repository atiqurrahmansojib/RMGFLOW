package com.rmgflow.sample.repository;

import com.rmgflow.sample.entity.Sample;
import com.rmgflow.sample.entity.SampleStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SampleRepository extends JpaRepository<Sample, Long> {
    boolean existsBySampleNoIgnoreCase(String sampleNo);

    Optional<Sample> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Sample> findByOrganizationId(Long organizationId, Pageable pageable);

    Page<Sample> findByOrganizationIdAndCurrentStatus(Long organizationId, SampleStatus status, Pageable pageable);
}
