-- Phase 3 (P3-T3, Document 8.9/15.4): the first cross-cutting module, built once and
-- reused by every later feature needing file/photo upload (Doc 6.3 principle).
-- organization_id is denormalized onto the attachment row itself (captured from the
-- uploader at write time) so every attachment read/download can be tenant-scoped
-- directly, without a per-entity-type resolver (same IDOR lesson as ADR-10/Doc 18).

CREATE TABLE attachments (
    id               BIGSERIAL PRIMARY KEY,
    organization_id  BIGINT NOT NULL REFERENCES organizations(id),
    entity_type      VARCHAR(50) NOT NULL,
    entity_id        BIGINT NOT NULL,
    file_name        VARCHAR(255) NOT NULL,
    storage_key      VARCHAR(255) NOT NULL,
    content_type     VARCHAR(100) NOT NULL,
    size_bytes       BIGINT NOT NULL,
    uploaded_by      BIGINT REFERENCES users(id),
    uploaded_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    checksum         VARCHAR(128),
    CONSTRAINT uq_attachments_storage_key UNIQUE (storage_key)
);
CREATE INDEX idx_attachments_entity ON attachments(entity_type, entity_id);
CREATE INDEX idx_attachments_organization_id ON attachments(organization_id);
