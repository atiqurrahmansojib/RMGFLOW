-- Phase 3 (P3-T1/T2, Document 8.3): inquiry lifecycle + factory candidate sourcing.

CREATE TABLE seasons (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    year       INT NOT NULL,
    start_date DATE,
    end_date   DATE,
    CONSTRAINT uq_seasons_name_year UNIQUE (name, year)
);

CREATE TABLE inquiries (
    id                   BIGSERIAL PRIMARY KEY,
    organization_id      BIGINT NOT NULL REFERENCES organizations(id),
    inquiry_no           VARCHAR(50) NOT NULL,
    buyer_id             BIGINT NOT NULL REFERENCES buyers(id),
    season_id            BIGINT REFERENCES seasons(id),
    merchandiser_id      BIGINT REFERENCES users(id),
    target_quantity      INT,
    target_price         NUMERIC(14,4),
    target_currency      VARCHAR(3) REFERENCES currencies(code),
    delivery_requirement DATE,
    status               VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    lost_reason          TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_inquiries_inquiry_no UNIQUE (inquiry_no),
    CONSTRAINT chk_inquiries_status CHECK (status IN ('OPEN', 'QUOTED', 'WON', 'LOST', 'HOLD')),
    -- Document 10.1/FR-20: LOST always carries a reason (Doc 4.3 lost-reason taxonomy).
    CONSTRAINT chk_inquiries_lost_reason CHECK (status != 'LOST' OR lost_reason IS NOT NULL)
);
CREATE INDEX idx_inquiries_organization_id ON inquiries(organization_id);
CREATE INDEX idx_inquiries_buyer_id ON inquiries(buyer_id);
CREATE INDEX idx_inquiries_status ON inquiries(status);
CREATE INDEX idx_inquiries_merchandiser_id ON inquiries(merchandiser_id);

CREATE TABLE inquiry_factory_candidates (
    id          BIGSERIAL PRIMARY KEY,
    inquiry_id  BIGINT NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
    factory_id  BIGINT NOT NULL REFERENCES factories(id),
    status      VARCHAR(20) NOT NULL DEFAULT 'CANDIDATE',
    CONSTRAINT uq_inquiry_factory_candidates UNIQUE (inquiry_id, factory_id),
    CONSTRAINT chk_inquiry_factory_candidates_status CHECK (status IN ('CANDIDATE', 'SELECTED', 'REJECTED'))
);
CREATE INDEX idx_inquiry_factory_candidates_inquiry_id ON inquiry_factory_candidates(inquiry_id);
