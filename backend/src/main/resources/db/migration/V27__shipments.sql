-- Phase 10 (P10-T1, Document 8.8/9.8): shipment tracking — this is where Quality's
-- final-inspection gate (Phase 9) and the shipment-quantity invariant (Doc 9.8) are
-- actually enforced, not just queryable.

CREATE TABLE shipments (
    id                 BIGSERIAL PRIMARY KEY,
    organization_id    BIGINT NOT NULL REFERENCES organizations(id),
    shipment_no        VARCHAR(50) NOT NULL,
    order_id           BIGINT NOT NULL REFERENCES orders(id),
    shipment_date      DATE,
    etd                DATE,
    eta                DATE,
    quantity_shipped   INT NOT NULL,
    cartons            INT,
    gross_weight       NUMERIC(10,2),
    net_weight         NUMERIC(10,2),
    volume_cbm         NUMERIC(10,3),
    port_of_loading    VARCHAR(150),
    port_of_discharge  VARCHAR(150),
    forwarder_id       BIGINT REFERENCES factories(id),
    shipping_line      VARCHAR(150),
    container_no       VARCHAR(50),
    bl_awb_no          VARCHAR(100),
    status             VARCHAR(20) NOT NULL DEFAULT 'BOOKED',
    is_partial         BOOLEAN NOT NULL DEFAULT FALSE,
    authorized_by      BIGINT REFERENCES users(id),
    override_reason    TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_shipments_shipment_no UNIQUE (shipment_no),
    CONSTRAINT chk_shipments_status CHECK (status IN ('BOOKED', 'IN_TRANSIT', 'DELIVERED', 'DELAYED')),
    CONSTRAINT chk_shipments_quantity_positive CHECK (quantity_shipped > 0)
);
CREATE INDEX idx_shipments_organization_id ON shipments(organization_id);
CREATE INDEX idx_shipments_order_id ON shipments(order_id);
