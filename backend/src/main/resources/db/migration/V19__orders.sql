-- Phase 6 (P6-T1/T2/T3, Document 8.6/9.4): order management, the aggregate root
-- that T&A/production/quality/shipment (later phases) all hang off.

CREATE TABLE orders (
    id                  BIGSERIAL PRIMARY KEY,
    organization_id     BIGINT NOT NULL REFERENCES organizations(id),
    order_no            VARCHAR(50) NOT NULL,
    buyer_po_no         VARCHAR(100) NOT NULL,
    buyer_id            BIGINT NOT NULL REFERENCES buyers(id),
    quotation_id        BIGINT REFERENCES quotations(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    order_date          DATE NOT NULL,
    ex_factory_date     DATE,
    delivery_date       DATE,
    incoterm            VARCHAR(3) REFERENCES incoterms(code),
    payment_terms_id    BIGINT REFERENCES payment_terms(id),
    destination_country VARCHAR(2) REFERENCES countries(code),
    total_value         NUMERIC(16,4) NOT NULL DEFAULT 0,
    currency            VARCHAR(3) NOT NULL REFERENCES currencies(code),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    version             INT NOT NULL DEFAULT 0,
    CONSTRAINT uq_orders_order_no UNIQUE (order_no),
    CONSTRAINT chk_orders_status CHECK (status IN (
        'CONFIRMED', 'IN_PROGRESS', 'PARTIALLY_SHIPPED', 'SHIPPED', 'CLOSED', 'CANCELLED'
    ))
    -- Document 8.6: buyer_po_no is intentionally NOT unique — one buyer PO can map
    -- to multiple internal `orders` rows (one per factory split, FR-71/73).
);
CREATE INDEX idx_orders_organization_id ON orders(organization_id);
CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_buyer_po_no ON orders(buyer_po_no);
CREATE INDEX idx_orders_status ON orders(status);

CREATE TABLE order_items (
    id         BIGSERIAL PRIMARY KEY,
    order_id   BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    style_id   BIGINT NOT NULL REFERENCES styles(id),
    factory_id BIGINT NOT NULL REFERENCES factories(id),
    color      VARCHAR(100),
    size       VARCHAR(50),
    quantity   INT NOT NULL,
    unit_price NUMERIC(14,4) NOT NULL,
    CONSTRAINT uq_order_items UNIQUE (order_id, style_id, factory_id, color, size),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0)
);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_factory_id ON order_items(factory_id);

-- Document 9.4: append-only amendment log — an order's commercial fields are never
-- updated directly without a corresponding amendment row written in the same
-- transaction (enforced in OrderService, not the schema alone, since `orders`
-- legitimately has system-maintained fields like status/total_value).
CREATE TABLE order_amendments (
    id            BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amendment_no  INT NOT NULL,
    field_changed VARCHAR(50) NOT NULL,
    old_value     TEXT,
    new_value     TEXT,
    reason        TEXT NOT NULL,
    requested_by  BIGINT REFERENCES users(id),
    approved_by   BIGINT REFERENCES users(id),
    status        VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    decided_at    TIMESTAMPTZ,
    CONSTRAINT uq_order_amendments UNIQUE (order_id, amendment_no),
    CONSTRAINT chk_order_amendments_status CHECK (status IN ('REQUESTED', 'APPROVED', 'REJECTED'))
);
CREATE INDEX idx_order_amendments_order_id ON order_amendments(order_id);

-- Document 9.3/9.4 invariant pattern applied to amendments too: a decided amendment
-- (APPROVED/REJECTED) is never re-decided.
CREATE OR REPLACE FUNCTION prevent_amendment_mutation_after_decision()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status != 'REQUESTED' THEN
        RAISE EXCEPTION 'Cannot modify an order amendment that is already %', OLD.status;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_amendment_mutation
    BEFORE UPDATE ON order_amendments
    FOR EACH ROW
    EXECUTE FUNCTION prevent_amendment_mutation_after_decision();
