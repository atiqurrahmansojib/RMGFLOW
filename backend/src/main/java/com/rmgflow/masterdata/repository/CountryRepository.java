package com.rmgflow.masterdata.repository;

import com.rmgflow.masterdata.entity.Country;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CountryRepository extends JpaRepository<Country, String> {
}
