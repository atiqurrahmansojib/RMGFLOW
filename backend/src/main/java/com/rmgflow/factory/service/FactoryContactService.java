package com.rmgflow.factory.service;

import com.rmgflow.factory.dto.FactoryContactRequest;
import com.rmgflow.factory.dto.FactoryContactResponse;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.entity.FactoryContact;
import com.rmgflow.factory.repository.FactoryContactRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FactoryContactService {

    private final FactoryContactRepository factoryContactRepository;
    private final FactoryService factoryService;

    @Transactional
    public FactoryContactResponse create(Long factoryId, FactoryContactRequest request) {
        // Security review fix: tenant-scoped lookup, same as FactoryService's own endpoints.
        Factory factory = factoryService.findInCurrentOrganization(factoryId);

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
        // Security review fix: 404s a cross-org factoryId instead of leaking its contacts.
        factoryService.findInCurrentOrganization(factoryId);
        return factoryContactRepository.findByFactoryId(factoryId).stream().map(this::toResponse).toList();
    }

    private FactoryContactResponse toResponse(FactoryContact contact) {
        return new FactoryContactResponse(contact.getId(), contact.getFactory().getId(), contact.getName(),
                contact.getRole(), contact.getEmail(), contact.getPhone(), contact.isPrimary());
    }
}
