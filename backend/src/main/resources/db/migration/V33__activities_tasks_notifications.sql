-- Phase 12 (P12, Document 8.9/20/21): cross-cutting activity timeline, tasks, and
-- notifications — generic (entity_type, entity_id) like attachments/documents
-- (Doc 6.3), attachable to any business entity rather than each module building
-- its own comment/task/notification table (Doc 56 rule 7).

CREATE TABLE activities (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES organizations(id),
    entity_type     VARCHAR(50) NOT NULL,
    entity_id       BIGINT NOT NULL,
    activity_type   VARCHAR(20) NOT NULL,
    occurred_at     TIMESTAMPTZ NOT NULL,
    logged_by       BIGINT REFERENCES users(id),
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_activities_type CHECK (activity_type IN ('CALL', 'EMAIL', 'MEETING', 'NOTE'))
);
CREATE INDEX idx_activities_entity ON activities(entity_type, entity_id);
CREATE INDEX idx_activities_organization_id ON activities(organization_id);

-- Document 21/§21: tasks are always attached to a real business entity, never
-- free-floating — entity_type/entity_id are NOT NULL (no generic to-do list here).
CREATE TABLE tasks (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES organizations(id),
    entity_type     VARCHAR(50) NOT NULL,
    entity_id       BIGINT NOT NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    assigned_to     BIGINT REFERENCES users(id),
    priority        VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
    due_date        DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_by      BIGINT REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_tasks_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT chk_tasks_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'CANCELLED'))
);
CREATE INDEX idx_tasks_entity ON tasks(entity_type, entity_id);
CREATE INDEX idx_tasks_organization_id ON tasks(organization_id);
CREATE INDEX idx_tasks_assigned_to_status ON tasks(assigned_to, status);

-- Document 8.9/13: a dispatch log, not the automation rule engine itself (full
-- rule configuration per Doc 13's notification_rules table is future work — this
-- is deliberately just the notification record a scheduled job or action writes to).
CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    entity_type VARCHAR(50),
    entity_id   BIGINT,
    message     TEXT NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user_id_is_read ON notifications(user_id, is_read);
