package com.rmgflow.quotation.repository;

import com.rmgflow.quotation.entity.Quotation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface QuotationRepository extends JpaRepository<Quotation, Long> {
    boolean existsByQuotationNoIgnoreCase(String quotationNo);

    Optional<Quotation> findByIdAndOrganizationId(Long id, Long organizationId);

    Optional<Quotation> findTopByQuotationNoOrderByVersionNoDesc(String quotationNo);

    Page<Quotation> findByOrganizationIdAndBuyerId(Long organizationId, Long buyerId, Pageable pageable);

    Page<Quotation> findByOrganizationId(Long organizationId, Pageable pageable);
}
