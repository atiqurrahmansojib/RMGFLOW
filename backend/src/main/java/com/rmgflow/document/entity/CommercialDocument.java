package com.rmgflow.document.entity;

import com.rmgflow.attachment.entity.Attachment;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import com.rmgflow.masterdata.entity.DocumentType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Document 8.8/9.9/FR-130: a new upload for the same (entityType, entityId,
 * documentType) always creates a new version — this entity has no update path for
 * an existing version's file_attachment_id, only CommercialDocumentService.upload()
 * which always inserts. Named CommercialDocument (not Document) to avoid colliding
 * with java.lang and other framework types named Document.
 */
@Entity
@Table(name = "documents")
@Getter
@Setter
@NoArgsConstructor
public class CommercialDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false)
    private DocumentEntityType entityType;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_type_id", nullable = false)
    private DocumentType documentType;

    @Column(name = "version_no", nullable = false)
    private int versionNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "file_attachment_id", nullable = false)
    private Attachment fileAttachment;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status = DocumentStatus.DRAFT;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private User owner;

    @Column(name = "uploaded_at", nullable = false, updatable = false)
    private Instant uploadedAt = Instant.now();

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Transient
    public boolean isExpired() {
        return expiryDate != null && expiryDate.isBefore(LocalDate.now());
    }
}
