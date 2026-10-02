-- Phase 9: permission codes for quality (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('QUALITY_VIEW',   'View inspections, defects, CAPA'),
    ('QUALITY_MANAGE', 'Create inspections/defects, manage CAPA records');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN' AND p.code IN ('QUALITY_VIEW','QUALITY_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD','GENERAL_MANAGER') AND p.code IN ('QUALITY_VIEW','QUALITY_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'QUALITY_INSPECTOR' AND p.code IN ('QUALITY_VIEW','QUALITY_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SENIOR_MERCHANDISER','JUNIOR_MERCHANDISER','COMMERCIAL_EXECUTIVE',
                  'PRODUCTION_FOLLOWUP','FACTORY_COORDINATOR','ACCOUNTS_FINANCE','MANAGEMENT_VIEWER')
  AND p.code = 'QUALITY_VIEW';
