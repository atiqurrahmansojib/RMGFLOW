-- Phase 11 (P11-T1, Document 8.8/9.10): operational profitability tracking — NOT a
-- general ledger (ADR-12 scope boundary). Receivable/payable OVERDUE status is
-- always computed at read time from due_date/received_amount, never manually set.

CREATE TABLE order_financials (
    id                          BIGSERIAL PRIMARY KEY,
    order_id                    BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    quoted_unit_price           NUMERIC(14,4),
    actual_cost_unit            NUMERIC(14,4),
    realized_unit_price         NUMERIC(14,4),
    CONSTRAINT uq_order_financials_order_id UNIQUE (order_id)
);

CREATE TABLE receivables (
    id               BIGSERIAL PRIMARY KEY,
    order_id         BIGINT NOT NULL REFERENCES orders(id),
    buyer_id         BIGINT NOT NULL REFERENCES buyers(id),
    amount           NUMERIC(16,4) NOT NULL,
    currency         VARCHAR(3) NOT NULL REFERENCES currencies(code),
    due_date         DATE NOT NULL,
    received_amount  NUMERIC(16,4) NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_receivables_order_id ON receivables(order_id);
CREATE INDEX idx_receivables_buyer_id ON receivables(buyer_id);
CREATE INDEX idx_receivables_due_date ON receivables(due_date);

CREATE TABLE payables (
    id            BIGSERIAL PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders(id),
    factory_id    BIGINT NOT NULL REFERENCES factories(id),
    amount        NUMERIC(16,4) NOT NULL,
    currency      VARCHAR(3) NOT NULL REFERENCES currencies(code),
    due_date      DATE NOT NULL,
    paid_amount   NUMERIC(16,4) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payables_order_id ON payables(order_id);
CREATE INDEX idx_payables_factory_id ON payables(factory_id);

CREATE TABLE payment_records (
    id             BIGSERIAL PRIMARY KEY,
    receivable_id  BIGINT REFERENCES receivables(id),
    payable_id     BIGINT REFERENCES payables(id),
    amount         NUMERIC(16,4) NOT NULL,
    paid_date      DATE NOT NULL,
    method         VARCHAR(50),
    reference_no   VARCHAR(100),
    recorded_by    BIGINT REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_payment_records_has_target CHECK (receivable_id IS NOT NULL OR payable_id IS NOT NULL)
);
CREATE INDEX idx_payment_records_receivable_id ON payment_records(receivable_id);
CREATE INDEX idx_payment_records_payable_id ON payment_records(payable_id);
