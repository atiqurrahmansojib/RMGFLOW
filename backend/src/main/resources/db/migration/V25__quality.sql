-- Phase 9 (P9-T1, Document 8.8/9.7): inline/midline/final inspections, defects, CAPA.

CREATE TABLE inspections (
    id             BIGSERIAL PRIMARY KEY,
    order_id       BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    inspection_type VARCHAR(20) NOT NULL,
    inspection_date DATE NOT NULL,
    inspected_qty  INT NOT NULL,
    aql_level      VARCHAR(10),
    result         VARCHAR(20) NOT NULL,
    inspector_id   BIGINT REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_inspections_type CHECK (inspection_type IN ('INLINE', 'MIDLINE', 'FINAL')),
    CONSTRAINT chk_inspections_result CHECK (result IN ('PASS', 'FAIL', 'REINSPECT'))
);
CREATE INDEX idx_inspections_order_id ON inspections(order_id);
-- Document 9.7/10.9: the exact query Phase 10's ShipmentService runs before allowing
-- a shipment to be created for an order.
CREATE INDEX idx_inspections_order_type_result ON inspections(order_id, inspection_type, result);

CREATE TABLE defects (
    id                BIGSERIAL PRIMARY KEY,
    inspection_id     BIGINT NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    defect_type_id    BIGINT NOT NULL REFERENCES defect_types(id),
    quantity          INT NOT NULL,
    severity          VARCHAR(20) NOT NULL,
    photo_document_id BIGINT REFERENCES attachments(id),
    CONSTRAINT chk_defects_severity CHECK (severity IN ('MINOR', 'MAJOR', 'CRITICAL')),
    CONSTRAINT chk_defects_quantity CHECK (quantity > 0)
);
CREATE INDEX idx_defects_inspection_id ON defects(inspection_id);

CREATE TABLE capa_records (
    id                  BIGSERIAL PRIMARY KEY,
    defect_id           BIGINT REFERENCES defects(id),
    inspection_id       BIGINT REFERENCES inspections(id),
    description         TEXT NOT NULL,
    corrective_action   TEXT,
    preventive_action   TEXT,
    factory_response    TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at           TIMESTAMPTZ,
    CONSTRAINT chk_capa_records_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'CLOSED')),
    CONSTRAINT chk_capa_records_has_source CHECK (defect_id IS NOT NULL OR inspection_id IS NOT NULL)
);
CREATE INDEX idx_capa_records_defect_id ON capa_records(defect_id);
CREATE INDEX idx_capa_records_inspection_id ON capa_records(inspection_id);
