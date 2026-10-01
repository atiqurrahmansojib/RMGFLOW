-- Phase 7: permission codes for T&A (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('TA_TEMPLATE_MANAGE', 'Create/edit T&A templates'),
    ('TA_VIEW',            'View T&A milestones for orders'),
    ('TA_UPDATE',          'Record actual dates / delay reasons on T&A milestones');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN' AND p.code IN ('TA_TEMPLATE_MANAGE','TA_VIEW','TA_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD','GENERAL_MANAGER') AND p.code IN ('TA_TEMPLATE_MANAGE','TA_VIEW','TA_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SENIOR_MERCHANDISER' AND p.code IN ('TA_TEMPLATE_MANAGE','TA_VIEW','TA_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'JUNIOR_MERCHANDISER' AND p.code IN ('TA_VIEW','TA_UPDATE');

-- Document 5.1/7: production/sampling/quality/commercial staff update the
-- milestones relevant to their stage of the critical path.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE','FACTORY_COORDINATOR')
  AND p.code IN ('TA_VIEW','TA_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('ACCOUNTS_FINANCE','MANAGEMENT_VIEWER') AND p.code = 'TA_VIEW';
