package com.rmgflow.factory.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.factory.dto.FactoryCapabilityRequest;
import com.rmgflow.factory.dto.FactoryCapabilityResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryCapability;
import com.rmgflow.factory.repository.FactoryCapabilityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FactoryCapabilityService {

    private final FactoryCapabilityRepository factoryCapabilityRepository;
    private final FactoryService factoryService;

    @Transactional
    public FactoryCapabilityResponse create(Long factoryId, FactoryCapabilityRequest request) {
        // Security review fix: tenant-scoped lookup before anything else.
        Factory factory = factoryService.findInCurrentOrganization(factoryId);

        if (factoryCapabilityRepository.existsByFactoryIdAndProductCategoryIgnoreCase(factoryId, request.productCategory())) {
            throw new ApiException(HttpStatus.CONFLICT, "This factory already lists that product category");
        }

        FactoryCapability capability = new FactoryCapability();
        capability.setFactory(factory);
        capability.setProductCategory(request.productCategory());
        capability = factoryCapabilityRepository.save(capability);
        return toResponse(capability);
    }

    @Transactional(readOnly = true)
    public List<FactoryCapabilityResponse> list(Long factoryId) {
        factoryService.findInCurrentOrganization(factoryId);
        return factoryCapabilityRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryCapabilityResponse toResponse(FactoryCapability capability) {
        return new FactoryCapabilityResponse(capability.getId(), capability.getFactory().getId(), capability.getProductCategory());
    }
}
