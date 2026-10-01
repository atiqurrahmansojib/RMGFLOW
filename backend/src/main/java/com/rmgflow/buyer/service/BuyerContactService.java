package com.rmgflow.buyer.service;

import com.rmgflow.buyer.dto.BuyerContactRequest;
import com.rmgflow.buyer.dto.BuyerContactResponse;
import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.entity.BuyerContact;
import com.rmgflow.buyer.repository.BuyerContactRepository;
import com.rmgflow.buyer.repository.BuyerRepository;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.service.AssignmentService;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Document 21 P2-T3: supports multiple contacts per buyer (FR-02), exactly one primary. */
@Service
@RequiredArgsConstructor
public class BuyerContactService {

    private final BuyerContactRepository buyerContactRepository;
    private final BuyerRepository buyerRepository;
    private final AssignmentService assignmentService;

    @Transactional
    public BuyerContactResponse create(Long buyerId, BuyerContactRequest request) {
        Buyer buyer = buyerRepository.findById(buyerId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Buyer not found"));
        requireEditAccess(buyer);

        if (request.primary()) {
            clearExistingPrimary(buyerId);
        } else if (!buyerContactRepository.existsByBuyerIdAndPrimaryTrue(buyerId)) {
            // Document 5.3/8.2 invariant: exactly one primary contact — the first
            // contact ever added to a buyer is always primary even if not requested.
            request = new BuyerContactRequest(request.name(), request.department(), request.email(), request.phone(), true);
        }

        BuyerContact contact = new BuyerContact();
        contact.setBuyer(buyer);
        contact.setName(request.name());
        contact.setDepartment(request.department());
        contact.setEmail(request.email());
        contact.setPhone(request.phone());
        contact.setPrimary(request.primary());
        contact = buyerContactRepository.save(contact);
        return toResponse(contact);
    }

    @Transactional(readOnly = true)
    public List<BuyerContactResponse> list(Long buyerId) {
        return buyerContactRepository.findByBuyerId(buyerId).stream().map(this::toResponse).toList();
    }

    private void clearExistingPrimary(Long buyerId) {
        buyerContactRepository.findByBuyerId(buyerId).stream()
                .filter(BuyerContact::isPrimary)
                .forEach(c -> {
                    c.setPrimary(false);
                    // Must flush before the new primary contact is INSERTed: Hibernate's
                    // default flush ordering runs INSERTs before UPDATEs within one flush,
                    // so without forcing this UPDATE through first, the new row's INSERT
                    // would momentarily violate uq_buyer_contacts_one_primary (two rows
                    // with primary=true at once) and fail the whole transaction.
                    buyerContactRepository.saveAndFlush(c);
                });
    }

    private void requireEditAccess(Buyer buyer) {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        boolean broadAccess = auth.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_GENERAL_MANAGER")
                        || a.getAuthority().equals("ROLE_OWNER_MD") || a.getAuthority().equals("ROLE_SENIOR_MERCHANDISER"));
        if (broadAccess) return;

        AuthenticatedUser user = (AuthenticatedUser) auth.getPrincipal();
        if (assignmentService.hasBuyerAccess(user, buyer.getId())) return;

        throw new AccessDeniedException("Not permitted to manage contacts for this buyer");
    }

    private BuyerContactResponse toResponse(BuyerContact contact) {
        return new BuyerContactResponse(
                contact.getId(), contact.getBuyer().getId(), contact.getName(),
                contact.getDepartment(), contact.getEmail(), contact.getPhone(), contact.isPrimary());
    }
}
