package com.rmgflow.inquiry.repository;

import com.rmgflow.inquiry.entity.Inquiry;
import com.rmgflow.inquiry.entity.InquiryStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InquiryRepository extends JpaRepository<Inquiry, Long> {
    boolean existsByInquiryNoIgnoreCase(String inquiryNo);

    Optional<Inquiry> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Inquiry> findByOrganizationId(Long organizationId, Pageable pageable);

    Page<Inquiry> findByOrganizationIdAndStatus(Long organizationId, InquiryStatus status, Pageable pageable);
}
