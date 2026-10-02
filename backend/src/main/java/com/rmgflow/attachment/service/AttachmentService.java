package com.rmgflow.attachment.service;

import com.rmgflow.attachment.config.StorageProperties;
import com.rmgflow.attachment.dto.AttachmentResponse;
import com.rmgflow.attachment.dto.DownloadUrlResponse;
import com.rmgflow.attachment.entity.Attachment;
import com.rmgflow.attachment.repository.AttachmentRepository;
import com.rmgflow.common.ApiException;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.List;

/**
 * Document 21 P3-T3: the first cross-cutting module (Doc 6.3) — every later feature
 * needing file/photo upload (samples, inspections, documents, …) calls this instead
 * of reimplementing upload/storage/access-control.
 */
@Service
@RequiredArgsConstructor
public class AttachmentService {

    private final AttachmentRepository attachmentRepository;
    private final StorageService storageService;
    private final AttachmentDownloadTokenService downloadTokenService;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final StorageProperties storageProperties;

    /**
     * Known limitation (acceptable for Phase 3): this generic module does not verify
     * that (entityType, entityId) actually exists or belongs to the caller's
     * organization before attaching a file to it — doing so would require a
     * per-entity-type resolver, which would make this foundational module depend on
     * every feature module built on top of it (circular). The attachment's OWN
     * organization_id is still stamped from the uploader and enforced on every read
     * (findInCurrentOrganization/list), so this cannot leak another organization's
     * attachment to this caller — the exposure is limited to an attachment
     * mis-linked to someone else's entity id, not cross-tenant data disclosure.
     * Revisit if a feature module needs to assert "this file is really attached to
     * MY style" with certainty (e.g. style detail screens listing attachments should
     * go through StyleService.findInCurrentOrganization first, then call this list()).
     */
    @Transactional
    public AttachmentResponse upload(String entityType, Long entityId, MultipartFile file) {
        String storageKey = storageService.store(file);

        Attachment attachment = new Attachment();
        attachment.setOrganization(organizationRepository.getReferenceById(currentUser().organizationId()));
        attachment.setEntityType(entityType);
        attachment.setEntityId(entityId);
        attachment.setFileName(sanitizeFileName(file.getOriginalFilename()));
        attachment.setStorageKey(storageKey);
        attachment.setContentType(file.getContentType());
        attachment.setSizeBytes(file.getSize());
        attachment.setUploadedBy(userRepository.getReferenceById(currentUser().id()));
        attachment.setChecksum(checksum(file));
        attachment = attachmentRepository.save(attachment);

        return toResponse(attachment);
    }

    @Transactional(readOnly = true)
    public List<AttachmentResponse> list(String entityType, Long entityId) {
        return attachmentRepository.findByEntityTypeAndEntityIdAndOrganizationId(entityType, entityId, currentUser().organizationId())
                .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public DownloadUrlResponse getDownloadUrl(Long attachmentId) {
        Attachment attachment = findInCurrentOrganization(attachmentId);
        String token = downloadTokenService.issue(attachment.getId());
        return new DownloadUrlResponse("/api/v1/attachments/download?token=" + token,
                storageProperties.downloadTokenTtlMinutes() * 60);
    }

    @Transactional(readOnly = true)
    public AttachmentDownload download(String token) {
        Long attachmentId = downloadTokenService.verifyAndGetAttachmentId(token);
        Attachment attachment = attachmentRepository.findById(attachmentId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Attachment not found"));
        InputStream stream = storageService.retrieve(attachment.getStorageKey());
        return new AttachmentDownload(stream, attachment.getFileName(), attachment.getContentType());
    }

    /** Public so other modules (e.g. CommercialDocumentService) can verify a
     * referenced attachment id is within the caller's tenant before linking to it. */
    public Attachment findInCurrentOrganization(Long attachmentId) {
        return attachmentRepository.findByIdAndOrganizationId(attachmentId, currentUser().organizationId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Attachment not found"));
    }

    private String sanitizeFileName(String originalFilename) {
        if (originalFilename == null) return "file";
        // Strip any path component a malicious client might smuggle in; the storage
        // KEY is never derived from this anyway (LocalFilesystemStorageService uses a
        // generated UUID), but the display name is still shown back to users.
        return java.nio.file.Paths.get(originalFilename).getFileName().toString();
    }

    private String checksum(MultipartFile file) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return Base64.getEncoder().encodeToString(digest.digest(file.getBytes()));
        } catch (NoSuchAlgorithmException | java.io.IOException e) {
            return null;
        }
    }

    private AttachmentResponse toResponse(Attachment attachment) {
        return new AttachmentResponse(attachment.getId(), attachment.getEntityType(), attachment.getEntityId(),
                attachment.getFileName(), attachment.getContentType(), attachment.getSizeBytes(),
                attachment.getUploadedBy() != null ? attachment.getUploadedBy().getId() : null, attachment.getUploadedAt());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }

    public record AttachmentDownload(InputStream stream, String fileName, String contentType) {
    }
}
