-- Phase 3 (P3-T4, Document 8.3): style master + append-only revisions.
-- style_revisions rows are NEVER updated after creation (FR-31/NFR-05) —
-- enforced at the service layer (StyleService only ever INSERTs a new revision).

CREATE TABLE styles (
    id                  BIGSERIAL PRIMARY KEY,
    organization_id     BIGINT NOT NULL REFERENCES organizations(id),
    style_no            VARCHAR(50) NOT NULL,
    buyer_id            BIGINT NOT NULL REFERENCES buyers(id),
    buyer_style_no      VARCHAR(100),
    product_category    VARCHAR(150),
    season_id           BIGINT REFERENCES seasons(id),
    gender              VARCHAR(20),
    description         VARCHAR(1000),
    current_revision_id BIGINT, -- FK added after style_revisions exists (see below)
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_styles_style_no UNIQUE (style_no)
);
CREATE INDEX idx_styles_organization_id ON styles(organization_id);
CREATE INDEX idx_styles_buyer_id ON styles(buyer_id);

CREATE TABLE style_revisions (
    id                 BIGSERIAL PRIMARY KEY,
    style_id           BIGINT NOT NULL REFERENCES styles(id) ON DELETE CASCADE,
    revision_no        INT NOT NULL,
    fabric             VARCHAR(255),
    composition        VARCHAR(255),
    gsm                NUMERIC(6,2),
    color              VARCHAR(100),
    size_range         VARCHAR(100),
    measurement_spec   JSONB,
    created_by         BIGINT REFERENCES users(id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_style_revisions UNIQUE (style_id, revision_no)
);
CREATE INDEX idx_style_revisions_style_id ON style_revisions(style_id);

ALTER TABLE styles ADD CONSTRAINT fk_styles_current_revision
    FOREIGN KEY (current_revision_id) REFERENCES style_revisions(id);
