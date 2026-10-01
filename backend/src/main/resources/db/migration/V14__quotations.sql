-- Phase 4 (P4-T3, Document 8.5/9.2): versioned quotation referencing an APPROVED costing.

CREATE TABLE quotations (
    id                     BIGSERIAL PRIMARY KEY,
    organization_id        BIGINT NOT NULL REFERENCES organizations(id),
    costing_id             BIGINT NOT NULL REFERENCES costings(id),
    quotation_no           VARCHAR(50) NOT NULL,
    version_no             INT NOT NULL,
    buyer_id               BIGINT NOT NULL REFERENCES buyers(id),
    style_id               BIGINT NOT NULL REFERENCES styles(id),
    quantity               INT NOT NULL,
    unit_price             NUMERIC(14,4) NOT NULL,
    currency               VARCHAR(3) NOT NULL REFERENCES currencies(code),
    incoterm               VARCHAR(3) REFERENCES incoterms(code),
    payment_terms_id       BIGINT REFERENCES payment_terms(id),
    validity_date          DATE,
    lead_time_days         INT,
    status                 VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    supersedes_quotation_id BIGINT REFERENCES quotations(id),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    version                INT NOT NULL DEFAULT 0,
    CONSTRAINT uq_quotations_no_version UNIQUE (quotation_no, version_no),
    CONSTRAINT chk_quotations_status CHECK (status IN (
        'DRAFT', 'SENT', 'NEGOTIATING', 'APPROVED', 'REJECTED', 'EXPIRED', 'SUPERSEDED'
    ))
);
CREATE INDEX idx_quotations_organization_id ON quotations(organization_id);
CREATE INDEX idx_quotations_buyer_id ON quotations(buyer_id);
CREATE INDEX idx_quotations_costing_id ON quotations(costing_id);

-- Document 9.2: an APPROVED quotation is immutable — same pattern as costing.
CREATE OR REPLACE FUNCTION prevent_quotation_mutation_after_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'APPROVED' THEN
        RAISE EXCEPTION 'Cannot modify an APPROVED quotation (id=%); create a new version instead', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_quotation_mutation
    BEFORE UPDATE ON quotations
    FOR EACH ROW
    EXECUTE FUNCTION prevent_quotation_mutation_after_approval();
