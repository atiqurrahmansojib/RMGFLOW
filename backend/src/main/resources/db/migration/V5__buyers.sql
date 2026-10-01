-- Phase 2 (P2-T2/T3, Document 8.2): buyer master, contacts, requirements.

CREATE TABLE buyers (
    id                        BIGSERIAL PRIMARY KEY,
    organization_id           BIGINT NOT NULL REFERENCES organizations(id),
    code                      VARCHAR(50) NOT NULL,
    name                      VARCHAR(255) NOT NULL,
    group_name                VARCHAR(255),
    country                   VARCHAR(2) REFERENCES countries(code),
    default_currency          VARCHAR(3) REFERENCES currencies(code),
    default_payment_terms_id  BIGINT REFERENCES payment_terms(id),
    default_incoterm          VARCHAR(3) REFERENCES incoterms(code),
    is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    version                   INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uq_buyers_code UNIQUE (code)
);
CREATE INDEX idx_buyers_organization_id ON buyers(organization_id);
CREATE INDEX idx_buyers_is_active ON buyers(is_active);

CREATE TABLE buyer_contacts (
    id         BIGSERIAL PRIMARY KEY,
    buyer_id   BIGINT NOT NULL REFERENCES buyers(id) ON DELETE CASCADE,
    name       VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    email      VARCHAR(255),
    phone      VARCHAR(50),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_buyer_contacts_buyer_id ON buyer_contacts(buyer_id);
-- Document 21 P2-T3 business rule: exactly one primary contact per buyer.
CREATE UNIQUE INDEX uq_buyer_contacts_one_primary ON buyer_contacts(buyer_id) WHERE is_primary;

CREATE TABLE buyer_requirements (
    id               BIGSERIAL PRIMARY KEY,
    buyer_id         BIGINT NOT NULL REFERENCES buyers(id) ON DELETE CASCADE,
    requirement_type VARCHAR(30) NOT NULL,
    detail           JSONB NOT NULL,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_buyer_requirements_type CHECK (
        requirement_type IN ('COMPLIANCE', 'QUALITY', 'DOCUMENT', 'COSTING_RULE', 'LEAD_TIME')
    )
);
CREATE INDEX idx_buyer_requirements_buyer_id ON buyer_requirements(buyer_id);
