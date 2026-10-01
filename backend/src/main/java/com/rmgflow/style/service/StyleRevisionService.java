package com.rmgflow.style.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.style.dto.StyleRevisionRequest;
import com.rmgflow.style.dto.StyleRevisionResponse;
import com.rmgflow.style.entity.Style;
import com.rmgflow.style.entity.StyleRevision;
import com.rmgflow.style.repository.StyleRevisionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Document 21 P3-T4/FR-31/NFR-05: creating a new revision NEVER updates a prior one —
 * there is deliberately no "edit revision" method anywhere in this class, only
 * create(). A new spec is always a new row; style_revisions is append-only by
 * construction (no code path exists to update an existing row), not merely by
 * convention — there's simply no UPDATE statement to misuse.
 */
@Service
@RequiredArgsConstructor
public class StyleRevisionService {

    private final StyleRevisionRepository styleRevisionRepository;
    private final StyleService styleService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public StyleRevisionResponse create(Long styleId, StyleRevisionRequest request) {
        Style style = styleService.findInCurrentOrganization(styleId);

        int nextRevisionNo = styleRevisionRepository.findTopByStyleIdOrderByRevisionNoDesc(styleId)
                .map(r -> r.getRevisionNo() + 1)
                .orElse(1);

        StyleRevision revision = new StyleRevision();
        revision.setStyle(style);
        revision.setRevisionNo(nextRevisionNo);
        revision.setFabric(request.fabric());
        revision.setComposition(request.composition());
        revision.setGsm(request.gsm());
        revision.setColor(request.color());
        revision.setSizeRange(request.sizeRange());
        revision.setMeasurementSpec(request.measurementSpecJson());
        revision.setCreatedBy(userRepository.getReferenceById(currentUser().id()));
        revision = styleRevisionRepository.save(revision);

        // Denormalized "latest" pointer on the style master — this IS an update, but
        // of the style row's pointer, never of the revision row itself (Doc 8.3).
        style.setCurrentRevision(revision);

        auditService.record("STYLE_REVISION_CREATE", "StyleRevision", revision.getId(), null, toResponse(revision), null);
        return toResponse(revision);
    }

    @Transactional(readOnly = true)
    public List<StyleRevisionResponse> list(Long styleId) {
        styleService.findInCurrentOrganization(styleId);
        return styleRevisionRepository.findByStyleIdOrderByRevisionNoDesc(styleId).stream().map(this::toResponse).toList();
    }

    private StyleRevisionResponse toResponse(StyleRevision revision) {
        return new StyleRevisionResponse(revision.getId(), revision.getStyle().getId(), revision.getRevisionNo(),
                revision.getFabric(), revision.getComposition(), revision.getGsm(), revision.getColor(),
                revision.getSizeRange(), revision.getMeasurementSpec(), revision.getCreatedAt());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
