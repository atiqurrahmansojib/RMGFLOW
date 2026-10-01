package com.rmgflow.sample.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.sample.dto.SampleRequest;
import com.rmgflow.sample.dto.SampleResponse;
import com.rmgflow.sample.entity.Sample;
import com.rmgflow.sample.entity.SampleStatus;
import com.rmgflow.sample.repository.SampleRepository;
import com.rmgflow.sample.repository.SampleTypeRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.style.service.StyleService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Document 21 P5-T1/FR-40/41: sample request lifecycle. Approval/revision logic
 * lives in SampleRevisionService (the actual append-only history); this service
 * owns only the parent request record and its derived current_status rollup. */
@Service
@RequiredArgsConstructor
public class SampleService {

    private final SampleRepository sampleRepository;
    private final SampleTypeRepository sampleTypeRepository;
    private final StyleService styleService;
    private final BuyerService buyerService;
    private final FactoryService factoryService;
    private final OrganizationRepository organizationRepository;
    private final AuditService auditService;

    @Transactional
    public SampleResponse create(SampleRequest request) {
        var style = styleService.findInCurrentOrganization(request.styleId());
        var buyer = buyerService.findInCurrentOrganization(request.buyerId());
        var factory = request.factoryId() != null ? factoryService.findInCurrentOrganization(request.factoryId()) : null;
        if (!sampleTypeRepository.existsById(request.sampleTypeId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Sample type not found");
        }

        Sample sample = new Sample();
        sample.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        sample.setSampleNo("SMP-" + UUID.randomUUID());
        sample.setStyle(style);
        sample.setBuyer(buyer);
        sample.setFactory(factory);
        sample.setSampleType(sampleTypeRepository.getReferenceById(request.sampleTypeId()));
        sample.setRequestDate(request.requestDate());
        sample.setRequiredDate(request.requiredDate());
        sample = sampleRepository.save(sample);

        auditService.record("SAMPLE_CREATE", "Sample", sample.getId(), null, toResponse(sample), null);
        return toResponse(sample);
    }

    @Transactional
    public void updateStatus(Long sampleId, SampleStatus status) {
        Sample sample = findInCurrentOrganization(sampleId);
        SampleStatus before = sample.getCurrentStatus();
        sample.setCurrentStatus(status);
        sampleRepository.save(sample);
        auditService.record("SAMPLE_STATUS_UPDATE", "Sample", sample.getId(), before, status, null);
    }

    @Transactional(readOnly = true)
    public SampleResponse get(Long sampleId) {
        return toResponse(findInCurrentOrganization(sampleId));
    }

    @Transactional(readOnly = true)
    public Page<SampleResponse> list(SampleStatus status, Pageable pageable) {
        Long organizationId = currentUser().organizationId();
        Page<Sample> page = status != null
                ? sampleRepository.findByOrganizationIdAndCurrentStatus(organizationId, status, pageable)
                : sampleRepository.findByOrganizationId(organizationId, pageable);
        return page.map(this::toResponse);
    }

    public Sample findInCurrentOrganization(Long sampleId) {
        return sampleRepository.findByIdAndOrganizationId(sampleId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Sample not found"));
    }

    private SampleResponse toResponse(Sample sample) {
        return new SampleResponse(sample.getId(), sample.getSampleNo(), sample.getStyle().getId(), sample.getBuyer().getId(),
                sample.getFactory() != null ? sample.getFactory().getId() : null, sample.getSampleType().getId(),
                sample.getRequestDate(), sample.getRequiredDate(), sample.getCurrentStatus());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
