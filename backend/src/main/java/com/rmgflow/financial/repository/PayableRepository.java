package com.rmgflow.financial.repository;

import com.rmgflow.financial.entity.Payable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PayableRepository extends JpaRepository<Payable, Long> {
    List<Payable> findByOrder_Organization_Id(Long organizationId);

    List<Payable> findByOrderId(Long orderId);

    Optional<Payable> findByIdAndOrder_Organization_Id(Long id, Long organizationId);
}
