-- Phase 4 (P4-T2, Document 8.5/9.1): versioned costing, immutable once approved.

CREATE TABLE costings (
    id                BIGSERIAL PRIMARY KEY,
    organization_id   BIGINT NOT NULL REFERENCES organizations(id),
    style_id          BIGINT NOT NULL REFERENCES styles(id),
    inquiry_id        BIGINT REFERENCES inquiries(id),
    version_no        INT NOT NULL,
    currency          VARCHAR(3) NOT NULL REFERENCES currencies(code),
    exchange_rate     NUMERIC(18,6) NOT NULL DEFAULT 1,
    quantity          INT NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    target_price      NUMERIC(14,4),
    total_cost        NUMERIC(14,4) NOT NULL DEFAULT 0,
    margin_percent    NUMERIC(6,3),
    superseded_from_id BIGINT REFERENCES costings(id),
    created_by        BIGINT REFERENCES users(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_at       TIMESTAMPTZ,
    version           INT NOT NULL DEFAULT 0,
    CONSTRAINT uq_costings_style_version UNIQUE (style_id, version_no),
    CONSTRAINT chk_costings_status CHECK (status IN ('DRAFT', 'APPROVED', 'SUPERSEDED'))
);
CREATE INDEX idx_costings_organization_id ON costings(organization_id);
CREATE INDEX idx_costings_style_id ON costings(style_id);

CREATE TABLE costing_items (
    id               BIGSERIAL PRIMARY KEY,
    costing_id       BIGINT NOT NULL REFERENCES costings(id) ON DELETE CASCADE,
    component_type   VARCHAR(30) NOT NULL,
    description      VARCHAR(255),
    unit_cost        NUMERIC(14,4) NOT NULL,
    consumption      NUMERIC(14,4) NOT NULL DEFAULT 1,
    wastage_percent  NUMERIC(5,2) NOT NULL DEFAULT 0,
    total_cost       NUMERIC(14,4) NOT NULL,
    CONSTRAINT chk_costing_items_component_type CHECK (component_type IN (
        'FABRIC', 'KNITTING', 'DYEING', 'FINISHING', 'TRIMS', 'CM', 'WASHING', 'PRINTING',
        'EMBROIDERY', 'TESTING', 'INSPECTION', 'PACKAGING', 'FREIGHT', 'COMMISSION',
        'BANK_CHARGE', 'WASTAGE', 'OVERHEAD', 'OTHER'
    ))
);
CREATE INDEX idx_costing_items_costing_id ON costing_items(costing_id);

-- Document 9.1/ADR-14: trigger-level immutability once APPROVED — defense in depth
-- alongside the service-layer guard (CostingService never issues an UPDATE to an
-- APPROVED costing's financial fields; this trigger makes that true even if a bug
-- or a future direct-DB access path tried to bypass the service).
CREATE OR REPLACE FUNCTION prevent_costing_mutation_after_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'APPROVED' THEN
        RAISE EXCEPTION 'Cannot modify an APPROVED costing (id=%); create a new version instead', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_costing_mutation
    BEFORE UPDATE ON costings
    FOR EACH ROW
    EXECUTE FUNCTION prevent_costing_mutation_after_approval();

CREATE OR REPLACE FUNCTION prevent_costing_item_mutation_if_costing_approved()
RETURNS TRIGGER AS $$
DECLARE
    costing_status VARCHAR(20);
BEGIN
    SELECT status INTO costing_status FROM costings WHERE id = COALESCE(NEW.costing_id, OLD.costing_id);
    IF costing_status = 'APPROVED' THEN
        RAISE EXCEPTION 'Cannot modify line items of an APPROVED costing (costing_id=%)', COALESCE(NEW.costing_id, OLD.costing_id);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_costing_item_insert
    BEFORE INSERT ON costing_items
    FOR EACH ROW
    EXECUTE FUNCTION prevent_costing_item_mutation_if_costing_approved();

CREATE TRIGGER trg_prevent_costing_item_update
    BEFORE UPDATE ON costing_items
    FOR EACH ROW
    EXECUTE FUNCTION prevent_costing_item_mutation_if_costing_approved();

CREATE TRIGGER trg_prevent_costing_item_delete
    BEFORE DELETE ON costing_items
    FOR EACH ROW
    EXECUTE FUNCTION prevent_costing_item_mutation_if_costing_approved();
