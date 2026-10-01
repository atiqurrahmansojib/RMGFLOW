package com.rmgflow.factory.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.factory.dto.FactoryContactRequest;
import com.rmgflow.factory.dto.FactoryContactResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryContact;
import com.rmgflow.factory.repository.FactoryContactRepository;
import com.rmgflow.factory.repository.FactoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FactoryContactService {

    private final FactoryContactRepository factoryContactRepository;
    private final FactoryRepository factoryRepository;

    @Transactional
    public FactoryContactResponse create(Long factoryId, FactoryContactRequest request) {
        Factory factory = factoryRepository.findById(factoryId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Factory not found"));

        boolean makePrimary = request.primary() || !factoryContactRepository.existsByFactoryIdAndPrimaryTrue(factoryId);
        if (request.primary()) {
            // saveAndFlush, not save: see BuyerContactService.clearExistingPrimary's
            // comment on the same Hibernate insert-before-update flush-ordering issue.
            factoryContactRepository.findByFactoryId(factoryId).stream()
                    .filter(FactoryContact::isPrimary)
                    .forEach(c -> {
                        c.setPrimary(false);
                        factoryContactRepository.saveAndFlush(c);
                    });
        }

        FactoryContact contact = new FactoryContact();
        contact.setFactory(factory);
        contact.setName(request.name());
        contact.setRole(request.role());
        contact.setEmail(request.email());
        contact.setPhone(request.phone());
        contact.setPrimary(makePrimary);
        contact = factoryContactRepository.save(contact);
        return toResponse(contact);
    }

    @Transactional(readOnly = true)
    public List<FactoryContactResponse> list(Long factoryId) {
        return factoryContactRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryContactResponse toResponse(FactoryContact contact) {
        return new FactoryContactResponse(contact.getId(), contact.getFactory().getId(), contact.getName(),
                contact.getRole(), contact.getEmail(), contact.getPhone(), contact.isPrimary());
    }
}
