package com.rmgflow.masterdata.repository;

import com.rmgflow.masterdata.entity.Incoterm;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IncotermRepository extends JpaRepository<Incoterm, String> {
}
