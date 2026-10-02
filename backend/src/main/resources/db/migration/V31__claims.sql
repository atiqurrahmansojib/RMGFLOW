-- Phase 11 (P11-T2, Document 8.8/10.8): post-shipment claims/disputes — a separate
-- append-only-in-spirit trail that never alters the original shipment/order
-- commercial records (Doc 9.11/NFR-05 immutability principle extended here).

CREATE TABLE claims (
    id              BIGSERIAL PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES orders(id),
    shipment_id     BIGINT REFERENCES shipments(id),
    raised_by       VARCHAR(20) NOT NULL,
    claim_type      VARCHAR(20) NOT NULL,
    description     TEXT NOT NULL,
    claimed_amount  NUMERIC(14,4),
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    resolution      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at     TIMESTAMPTZ,
    CONSTRAINT chk_claims_raised_by CHECK (raised_by IN ('BUYER', 'INTERNAL')),
    CONSTRAINT chk_claims_type CHECK (claim_type IN ('SHORT_SHIPMENT', 'QUALITY', 'DELAY', 'OTHER')),
    CONSTRAINT chk_claims_status CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED'))
);
CREATE INDEX idx_claims_order_id ON claims(order_id);
CREATE INDEX idx_claims_status ON claims(status);
