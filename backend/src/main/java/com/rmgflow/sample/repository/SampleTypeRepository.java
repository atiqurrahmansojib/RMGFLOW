package com.rmgflow.sample.repository;

import com.rmgflow.sample.entity.SampleType;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SampleTypeRepository extends JpaRepository<SampleType, Long> {
}
