package com.rmgflow.attachment.entity;

import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/**
 * Document 6.3/8.9/15.4: the first cross-cutting module — a generic (entityType,
 * entityId) attachment reused by every later feature needing file/photo upload,
 * per Doc 56 rule 7 (no unnecessary duplicate "attachments" tables per module).
 * organization_id is denormalized here (not resolved from entityType/entityId at
 * read time) so every attachment query can be tenant-scoped directly — see the
 * migration comment and ADR-10 for why that matters.
 */
@Entity
@Table(name = "attachments")
@Getter
@Setter
@NoArgsConstructor
public class Attachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "entity_type", nullable = false)
    private String entityType;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Column(name = "storage_key", nullable = false, unique = true)
    private String storageKey;

    @Column(name = "content_type", nullable = false)
    private String contentType;

    @Column(name = "size_bytes", nullable = false)
    private long sizeBytes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by")
    private User uploadedBy;

    @Column(name = "uploaded_at", nullable = false, updatable = false)
    private Instant uploadedAt = Instant.now();

    private String checksum;
}
