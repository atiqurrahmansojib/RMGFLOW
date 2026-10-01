-- Phase 5: permission codes for sampling (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('SAMPLE_VIEW',    'View samples and revisions'),
    ('SAMPLE_MANAGE',  'Create sample requests, revisions, submit for approval'),
    ('SAMPLE_APPROVE', 'Record the buyer''s approval/rejection decision on a sample revision');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN' AND p.code IN ('SAMPLE_VIEW','SAMPLE_MANAGE','SAMPLE_APPROVE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER', 'SENIOR_MERCHANDISER')
  AND p.code IN ('SAMPLE_VIEW','SAMPLE_MANAGE','SAMPLE_APPROVE');

-- Document 5.1/7: Sampling Coordinator owns the day-to-day sample workflow.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SAMPLING_COORDINATOR' AND p.code IN ('SAMPLE_VIEW','SAMPLE_MANAGE','SAMPLE_APPROVE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'JUNIOR_MERCHANDISER' AND p.code IN ('SAMPLE_VIEW','SAMPLE_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE','ACCOUNTS_FINANCE',
                  'MANAGEMENT_VIEWER','FACTORY_COORDINATOR')
  AND p.code = 'SAMPLE_VIEW';
