package com.rmgflow.style.repository;

import com.rmgflow.style.entity.StyleRevision;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StyleRevisionRepository extends JpaRepository<StyleRevision, Long> {
    List<StyleRevision> findByStyleIdOrderByRevisionNoDesc(Long styleId);

    Optional<StyleRevision> findTopByStyleIdOrderByRevisionNoDesc(Long styleId);
}
