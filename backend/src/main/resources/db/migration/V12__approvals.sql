-- Phase 4 (P4-T1, Document 8.4/ADR-08): the shared approval engine used by costing,
-- quotation, sampling, quality gates, shipment, and documents — one implementation,
-- many attachment points via (target_type, target_id), per Doc 6.3/56 rule 7.
-- organization_id is denormalized here too (same ADR-10 lesson as attachments) so
-- every approval query is tenant-scoped without resolving the target first.

CREATE TABLE approvals (
    id               BIGSERIAL PRIMARY KEY,
    organization_id  BIGINT NOT NULL REFERENCES organizations(id),
    target_type      VARCHAR(30) NOT NULL,
    target_id        BIGINT NOT NULL,
    round_no         INT NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    submitted_by     BIGINT REFERENCES users(id),
    submitted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    decided_by       BIGINT REFERENCES users(id),
    decided_at       TIMESTAMPTZ,
    comments         TEXT,
    rejection_reason TEXT,
    CONSTRAINT uq_approvals_target_round UNIQUE (target_type, target_id, round_no),
    CONSTRAINT chk_approvals_target_type CHECK (target_type IN (
        'COSTING', 'QUOTATION', 'SAMPLE_REVISION', 'LAB_DIP', 'TRIM', 'PP_SAMPLE',
        'INSPECTION', 'SHIPMENT', 'DOCUMENT'
    )),
    CONSTRAINT chk_approvals_status CHECK (status IN (
        'SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED', 'RETURNED', 'RESUBMITTED', 'WITHDRAWN'
    ))
);
CREATE INDEX idx_approvals_target ON approvals(target_type, target_id);
CREATE INDEX idx_approvals_organization_id ON approvals(organization_id);
CREATE INDEX idx_approvals_status ON approvals(status);

-- Document 8.4/9.3: a decided approval round is immutable — rejection creates a NEW
-- round (new row), it never flips an existing row's status. Enforced at the DB level,
-- not just by application discipline (same defense-in-depth as costing immutability).
CREATE OR REPLACE FUNCTION prevent_approval_mutation_after_decision()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.decided_at IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot modify an approval round that has already been decided (id=%, decided_at=%)', OLD.id, OLD.decided_at;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_approval_mutation
    BEFORE UPDATE ON approvals
    FOR EACH ROW
    EXECUTE FUNCTION prevent_approval_mutation_after_decision();
