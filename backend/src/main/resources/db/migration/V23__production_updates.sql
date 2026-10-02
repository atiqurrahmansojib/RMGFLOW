-- Phase 8 (P8-T1, Document 8.8/9.6): daily production tracking. Cumulative totals
-- are ALWAYS derived by summing this table — there is no stored running-total
-- column anywhere, by construction, so "forgot to update the cumulative field"
-- (Doc 9.6's own stated motivation) is not a bug class that can occur here.

CREATE TABLE production_updates (
    id             BIGSERIAL PRIMARY KEY,
    order_id       BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    update_date    DATE NOT NULL,
    cutting_qty    INT NOT NULL DEFAULT 0,
    sewing_qty     INT NOT NULL DEFAULT 0,
    finishing_qty  INT NOT NULL DEFAULT 0,
    packing_qty    INT NOT NULL DEFAULT 0,
    rejection_qty  INT NOT NULL DEFAULT 0,
    alteration_qty INT NOT NULL DEFAULT 0,
    entered_by     BIGINT REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_production_updates UNIQUE (order_id, update_date),
    CONSTRAINT chk_production_updates_non_negative CHECK (
        cutting_qty >= 0 AND sewing_qty >= 0 AND finishing_qty >= 0 AND
        packing_qty >= 0 AND rejection_qty >= 0 AND alteration_qty >= 0
    )
);
CREATE INDEX idx_production_updates_order_id ON production_updates(order_id);
