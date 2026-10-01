-- Phase 2 (P2-T4/T5, Document 8.2): factory/vendor master, contacts,
-- capabilities, certifications, buyer-approval gate.

CREATE TABLE factories (
    id               BIGSERIAL PRIMARY KEY,
    organization_id  BIGINT NOT NULL REFERENCES organizations(id),
    code             VARCHAR(50) NOT NULL,
    name             VARCHAR(255) NOT NULL,
    partner_type     VARCHAR(30) NOT NULL,
    legal_entity_name VARCHAR(255),
    address          VARCHAR(500),
    country          VARCHAR(2) REFERENCES countries(code),
    capacity_per_month INTEGER,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    version          INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uq_factories_code UNIQUE (code),
    CONSTRAINT chk_factories_partner_type CHECK (partner_type IN (
        'GARMENT_FACTORY', 'FABRIC_SUPPLIER', 'TRIM_SUPPLIER', 'WASHING', 'PRINTING',
        'EMBROIDERY', 'TESTING_LAB', 'INSPECTION_AGENCY', 'FREIGHT_FORWARDER', 'OTHER'
    ))
);
CREATE INDEX idx_factories_organization_id ON factories(organization_id);
CREATE INDEX idx_factories_partner_type ON factories(partner_type);
CREATE INDEX idx_factories_is_active ON factories(is_active);

CREATE TABLE factory_contacts (
    id         BIGSERIAL PRIMARY KEY,
    factory_id BIGINT NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
    name       VARCHAR(255) NOT NULL,
    role       VARCHAR(100),
    email      VARCHAR(255),
    phone      VARCHAR(50),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_factory_contacts_factory_id ON factory_contacts(factory_id);
CREATE UNIQUE INDEX uq_factory_contacts_one_primary ON factory_contacts(factory_id) WHERE is_primary;

CREATE TABLE factory_capabilities (
    id               BIGSERIAL PRIMARY KEY,
    factory_id       BIGINT NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
    product_category VARCHAR(150) NOT NULL,
    CONSTRAINT uq_factory_capabilities UNIQUE (factory_id, product_category)
);

CREATE TABLE factory_certifications (
    id            BIGSERIAL PRIMARY KEY,
    factory_id    BIGINT NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
    cert_name     VARCHAR(150) NOT NULL,
    issued_date   DATE,
    expiry_date   DATE,
    document_id   BIGINT
);
CREATE INDEX idx_factory_certifications_factory_id ON factory_certifications(factory_id);
CREATE INDEX idx_factory_certifications_expiry ON factory_certifications(expiry_date);

-- Document 9.4 hard rule: a factory not approved by a buyer cannot be assigned to
-- that buyer's order without explicit override. Enforced in OrderService (Phase 6);
-- this table is the data source that check reads.
CREATE TABLE factory_buyer_approvals (
    id            BIGSERIAL PRIMARY KEY,
    factory_id    BIGINT NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
    buyer_id      BIGINT NOT NULL REFERENCES buyers(id) ON DELETE CASCADE,
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    approved_date DATE,
    expiry_date   DATE,
    CONSTRAINT uq_factory_buyer_approvals UNIQUE (factory_id, buyer_id),
    CONSTRAINT chk_factory_buyer_approvals_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED'))
);
CREATE INDEX idx_factory_buyer_approvals_buyer_id ON factory_buyer_approvals(buyer_id);
