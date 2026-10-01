package com.rmgflow.masterdata.repository;

import com.rmgflow.masterdata.entity.Season;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SeasonRepository extends JpaRepository<Season, Long> {
}
