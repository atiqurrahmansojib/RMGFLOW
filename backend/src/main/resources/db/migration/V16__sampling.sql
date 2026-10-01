-- Phase 5 (P5-T1/T2, Document 8.4/9.3): sample lifecycle. sample_revisions +
-- the shared approvals table (ApprovalTargetType.SAMPLE_REVISION) together
-- implement "a rejected sample never becomes approved by editing" (Doc 9.3) —
-- rejection creates a new revision row + a new approval round, nothing here
-- is ever mutated after creation except samples.current_status, which is a
-- derived rollup field, not the source of truth.

CREATE TABLE sample_types (
    id                BIGSERIAL PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    is_buyer_specific BOOLEAN NOT NULL DEFAULT FALSE,
    buyer_id          BIGINT REFERENCES buyers(id),
    CONSTRAINT uq_sample_types_name_buyer UNIQUE (name, buyer_id)
);

CREATE TABLE samples (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES organizations(id),
    sample_no       VARCHAR(50) NOT NULL,
    style_id        BIGINT NOT NULL REFERENCES styles(id),
    buyer_id        BIGINT NOT NULL REFERENCES buyers(id),
    factory_id      BIGINT REFERENCES factories(id),
    sample_type_id  BIGINT NOT NULL REFERENCES sample_types(id),
    request_date    DATE NOT NULL,
    required_date   DATE,
    current_status  VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_samples_sample_no UNIQUE (sample_no),
    CONSTRAINT chk_samples_current_status CHECK (current_status IN (
        'REQUESTED', 'SUBMITTED', 'APPROVED', 'REJECTED', 'RETURNED'
    ))
);
CREATE INDEX idx_samples_organization_id ON samples(organization_id);
CREATE INDEX idx_samples_style_id ON samples(style_id);
CREATE INDEX idx_samples_status_required_date ON samples(current_status, required_date);

CREATE TABLE sample_revisions (
    id              BIGSERIAL PRIMARY KEY,
    sample_id       BIGINT NOT NULL REFERENCES samples(id) ON DELETE CASCADE,
    revision_no     INT NOT NULL,
    submitted_date  DATE,
    comments        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_sample_revisions UNIQUE (sample_id, revision_no)
);
CREATE INDEX idx_sample_revisions_sample_id ON sample_revisions(sample_id);
