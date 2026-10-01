package com.rmgflow.inquiry.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateRequest;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateResponse;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateStatusRequest;
import com.rmgflow.inquiry.entity.Inquiry;
import com.rmgflow.inquiry.entity.InquiryFactoryCandidate;
import com.rmgflow.inquiry.repository.InquiryFactoryCandidateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 10.1/FR-21: factory sourcing/feasibility step of the inquiry lifecycle. */
@Service
@RequiredArgsConstructor
public class InquiryFactoryCandidateService {

    private final InquiryFactoryCandidateRepository candidateRepository;
    private final InquiryService inquiryService;
    private final FactoryService factoryService;

    @Transactional
    public InquiryFactoryCandidateResponse create(Long inquiryId, InquiryFactoryCandidateRequest request) {
        Inquiry inquiry = inquiryService.findInCurrentOrganization(inquiryId);
        Factory factory = factoryService.findInCurrentOrganization(request.factoryId());

        if (candidateRepository.existsByInquiryIdAndFactoryId(inquiryId, request.factoryId())) {
            throw new ApiException(HttpStatus.CONFLICT, "This factory is already a candidate for this inquiry");
        }

        InquiryFactoryCandidate candidate = new InquiryFactoryCandidate();
        candidate.setInquiry(inquiry);
        candidate.setFactory(factory);
        candidate = candidateRepository.save(candidate);
        return toResponse(candidate);
    }

    @Transactional
    public InquiryFactoryCandidateResponse updateStatus(Long inquiryId, Long candidateId, InquiryFactoryCandidateStatusRequest request) {
        inquiryService.findInCurrentOrganization(inquiryId);
        InquiryFactoryCandidate candidate = candidateRepository.findById(candidateId)
                .filter(c -> c.getInquiry().getId().equals(inquiryId))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Candidate not found"));
        candidate.setStatus(request.status());
        candidate = candidateRepository.save(candidate);
        return toResponse(candidate);
    }

    @Transactional(readOnly = true)
    public List<InquiryFactoryCandidateResponse> list(Long inquiryId) {
        inquiryService.findInCurrentOrganization(inquiryId);
        return candidateRepository.findByInquiryId(inquiryId).stream().map(this::toResponse).toList();
    }

    private InquiryFactoryCandidateResponse toResponse(InquiryFactoryCandidate candidate) {
        return new InquiryFactoryCandidateResponse(candidate.getId(), candidate.getInquiry().getId(),
                candidate.getFactory().getId(), candidate.getFactory().getName(), candidate.getStatus());
    }
}
