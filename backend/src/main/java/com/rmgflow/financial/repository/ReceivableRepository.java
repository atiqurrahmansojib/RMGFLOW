package com.rmgflow.financial.repository;

import com.rmgflow.financial.entity.Receivable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReceivableRepository extends JpaRepository<Receivable, Long> {
    List<Receivable> findByOrder_Organization_Id(Long organizationId);

    List<Receivable> findByOrderId(Long orderId);

    Optional<Receivable> findByIdAndOrder_Organization_Id(Long id, Long organizationId);
}
