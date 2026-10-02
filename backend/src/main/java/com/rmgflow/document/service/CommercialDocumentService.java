package com.rmgflow.document.service;

import com.rmgflow.attachment.entity.Attachment;
import com.rmgflow.attachment.service.AttachmentService;
import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.document.dto.CommercialDocumentRequest;
import com.rmgflow.document.dto.CommercialDocumentResponse;
import com.rmgflow.document.entity.CommercialDocument;
import com.rmgflow.document.repository.CommercialDocumentRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.masterdata.repository.DocumentTypeRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Document 8.8/9.9/FR-130: a new upload for the same (entityType, entityId,
 * documentType) ALWAYS creates a new version — there is no update method here,
 * only create(), same append-only-by-construction discipline as style/sample
 * revisions. Expiry (Doc 9.9/13 A12) is computed at read time via
 * CommercialDocument.isExpired(), never a stale stored flag.
 */
@Service
@RequiredArgsConstructor
public class CommercialDocumentService {

    private final CommercialDocumentRepository commercialDocumentRepository;
    private final AttachmentService attachmentService;
    private final DocumentTypeRepository documentTypeRepository;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public CommercialDocumentResponse upload(CommercialDocumentRequest request) {
        Attachment attachment = attachmentService.findInCurrentOrganization(request.fileAttachmentId());
        if (!documentTypeRepository.existsById(request.documentTypeId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Document type not found");
        }

        int nextVersion = commercialDocumentRepository
                .findTopByEntityTypeAndEntityIdAndDocumentTypeIdOrderByVersionNoDesc(request.entityType(), request.entityId(), request.documentTypeId())
                .map(d -> d.getVersionNo() + 1)
                .orElse(1);

        CommercialDocument document = new CommercialDocument();
        document.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        document.setEntityType(request.entityType());
        document.setEntityId(request.entityId());
        document.setDocumentType(documentTypeRepository.getReferenceById(request.documentTypeId()));
        document.setVersionNo(nextVersion);
        document.setFileAttachment(attachment);
        document.setOwner(userRepository.getReferenceById(currentUser().id()));
        document.setExpiryDate(request.expiryDate());
        document = commercialDocumentRepository.save(document);

        auditService.record("DOCUMENT_UPLOAD", request.entityType().name(), request.entityId(), null, toResponse(document), null);
        return toResponse(document);
    }

    @Transactional(readOnly = true)
    public List<CommercialDocumentResponse> list(com.rmgflow.document.entity.DocumentEntityType entityType, Long entityId) {
        return commercialDocumentRepository.findByEntityTypeAndEntityIdAndOrganizationId(entityType, entityId, currentUser().organizationId())
                .stream().map(this::toResponse).toList();
    }

    @Transactional
    public CommercialDocumentResponse approve(Long documentId) {
        CommercialDocument document = findInCurrentOrganization(documentId);
        document.setStatus(com.rmgflow.document.entity.DocumentStatus.APPROVED);
        document = commercialDocumentRepository.save(document);
        return toResponse(document);
    }

    private CommercialDocument findInCurrentOrganization(Long documentId) {
        return commercialDocumentRepository.findByIdAndOrganizationId(documentId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Document not found"));
    }

    private CommercialDocumentResponse toResponse(CommercialDocument document) {
        return new CommercialDocumentResponse(document.getId(), document.getEntityType(), document.getEntityId(),
                document.getDocumentType().getId(), document.getVersionNo(), document.getFileAttachment().getId(),
                document.getStatus(), document.getOwner() != null ? document.getOwner().getId() : null,
                document.getUploadedAt(), document.getExpiryDate(), document.isExpired());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
