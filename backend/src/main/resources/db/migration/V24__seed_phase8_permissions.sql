-- Phase 8: permission codes for production follow-up (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('PRODUCTION_VIEW',   'View production updates and progress'),
    ('PRODUCTION_UPDATE', 'Enter/correct daily production quantities');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN' AND p.code IN ('PRODUCTION_VIEW','PRODUCTION_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD','GENERAL_MANAGER','SENIOR_MERCHANDISER') AND p.code IN ('PRODUCTION_VIEW','PRODUCTION_UPDATE');

-- Document 5.1/7: Production Follow-up Officer and Factory Coordinator own daily entry.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('PRODUCTION_FOLLOWUP','FACTORY_COORDINATOR') AND p.code IN ('PRODUCTION_VIEW','PRODUCTION_UPDATE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('JUNIOR_MERCHANDISER','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE','ACCOUNTS_FINANCE','MANAGEMENT_VIEWER')
  AND p.code = 'PRODUCTION_VIEW';
