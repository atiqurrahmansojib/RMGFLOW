package com.rmgflow.production.repository;

import com.rmgflow.production.entity.ProductionUpdate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ProductionUpdateRepository extends JpaRepository<ProductionUpdate, Long> {
    List<ProductionUpdate> findByOrderIdOrderByUpdateDate(Long orderId);

    Optional<ProductionUpdate> findByOrderIdAndUpdateDate(Long orderId, LocalDate updateDate);
}
