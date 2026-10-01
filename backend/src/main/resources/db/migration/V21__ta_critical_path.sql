-- Phase 7 (P7-T1/T2/T3/T4, Document 8.7/9.5/10.3): configurable T&A templates
-- instantiated into per-order milestone instances at order confirmation.

CREATE TABLE ta_templates (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES organizations(id),
    name            VARCHAR(150) NOT NULL,
    buyer_id        BIGINT REFERENCES buyers(id),
    style_id        BIGINT REFERENCES styles(id),
    is_default      BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_ta_templates_organization_id ON ta_templates(organization_id);

CREATE TABLE ta_template_milestones (
    id                          BIGSERIAL PRIMARY KEY,
    template_id                 BIGINT NOT NULL REFERENCES ta_templates(id) ON DELETE CASCADE,
    milestone_type_id           BIGINT NOT NULL REFERENCES milestone_types(id),
    sequence                    INT NOT NULL,
    offset_days_from_exfactory  INT NOT NULL,
    depends_on_milestone_id     BIGINT REFERENCES ta_template_milestones(id),
    CONSTRAINT uq_ta_template_milestones UNIQUE (template_id, sequence)
);
CREATE INDEX idx_ta_template_milestones_template_id ON ta_template_milestones(template_id);

-- Document 8.7/9.5: `status` is a convenience column recomputed by a scheduled job
-- (Phase 11+) and on every read mapping (TaMilestoneService) — it is NEVER the
-- source of truth for "is this overdue"; planned_date/revised_date/actual_date are.
CREATE TABLE ta_milestones (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    milestone_type_id       BIGINT NOT NULL REFERENCES milestone_types(id),
    sequence                INT NOT NULL,
    planned_date            DATE NOT NULL,
    revised_date            DATE,
    actual_date             DATE,
    responsible_user_id     BIGINT REFERENCES users(id),
    responsible_factory_id  BIGINT REFERENCES factories(id),
    status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    depends_on_milestone_id BIGINT REFERENCES ta_milestones(id),
    delay_reason            TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_ta_milestones UNIQUE (order_id, sequence),
    CONSTRAINT chk_ta_milestones_status CHECK (status IN (
        'PENDING', 'UPCOMING', 'DUE_TODAY', 'OVERDUE', 'CRITICAL_DELAY', 'BLOCKED', 'DONE'
    ))
);
CREATE INDEX idx_ta_milestones_order_id ON ta_milestones(order_id);
CREATE INDEX idx_ta_milestones_status_planned_date ON ta_milestones(status, planned_date);
