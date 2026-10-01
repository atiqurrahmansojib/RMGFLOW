package com.rmgflow.inquiry.repository;

import com.rmgflow.inquiry.entity.InquiryFactoryCandidate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InquiryFactoryCandidateRepository extends JpaRepository<InquiryFactoryCandidate, Long> {
    List<InquiryFactoryCandidate> findByInquiryId(Long inquiryId);

    boolean existsByInquiryIdAndFactoryId(Long inquiryId, Long factoryId);
}
