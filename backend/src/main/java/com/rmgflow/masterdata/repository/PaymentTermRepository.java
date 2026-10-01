package com.rmgflow.masterdata.repository;

import com.rmgflow.masterdata.entity.PaymentTerm;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentTermRepository extends JpaRepository<PaymentTerm, Long> {
}
