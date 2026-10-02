-- Phase 10 (P10-T2, Document 8.8/9.9): commercial/compliance documents. Generic
-- (entity_type, entity_id) like attachments (Doc 6.3), but version-tracked and
-- typed against document_types (Doc 8.2) rather than a free-form file bag — a new
-- upload for the same (entity_type, entity_id, document_type_id) always creates a
-- new version_no, it never overwrites a prior one (FR-130).

CREATE TABLE documents (
    id               BIGSERIAL PRIMARY KEY,
    organization_id  BIGINT NOT NULL REFERENCES organizations(id),
    entity_type      VARCHAR(30) NOT NULL,
    entity_id        BIGINT NOT NULL,
    document_type_id BIGINT NOT NULL REFERENCES document_types(id),
    version_no       INT NOT NULL,
    file_attachment_id BIGINT NOT NULL REFERENCES attachments(id),
    status           VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    owner_id         BIGINT REFERENCES users(id),
    uploaded_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expiry_date      DATE,
    CONSTRAINT uq_documents_version UNIQUE (entity_type, entity_id, document_type_id, version_no),
    CONSTRAINT chk_documents_entity_type CHECK (entity_type IN ('ORDER', 'SHIPMENT', 'FACTORY', 'STYLE')),
    CONSTRAINT chk_documents_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'EXPIRED'))
);
CREATE INDEX idx_documents_entity ON documents(entity_type, entity_id);
CREATE INDEX idx_documents_organization_id ON documents(organization_id);
CREATE INDEX idx_documents_expiry ON documents(expiry_date);
