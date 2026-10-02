-- Phase 12: permission codes for activity/task/notification/dashboard (Document 5.2).
-- Broadly granted — these are cross-cutting conveniences, not sensitive commercial data.

INSERT INTO permissions (code, description) VALUES
    ('ACTIVITY_VIEW',   'View activity timeline entries'),
    ('ACTIVITY_MANAGE', 'Log activity entries (calls/emails/meetings/notes)'),
    ('TASK_VIEW',       'View tasks'),
    ('TASK_MANAGE',     'Create/update/assign tasks');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SUPER_ADMIN','OWNER_MD','GENERAL_MANAGER','SENIOR_MERCHANDISER','JUNIOR_MERCHANDISER',
                  'SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE',
                  'ACCOUNTS_FINANCE','FACTORY_COORDINATOR')
  AND p.code IN ('ACTIVITY_VIEW','ACTIVITY_MANAGE','TASK_VIEW','TASK_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'MANAGEMENT_VIEWER' AND p.code IN ('ACTIVITY_VIEW','TASK_VIEW');
