-- Phase 2: permission codes for buyer/factory management (Document 5.2 matrix row).

INSERT INTO permissions (code, description) VALUES
    ('BUYER_VIEW',      'View buyer records'),
    ('BUYER_MANAGE',    'Create/edit any buyer'),
    ('BUYER_MANAGE_OWN','Create/edit only assigned buyers'),
    ('FACTORY_VIEW',    'View factory/vendor records'),
    ('FACTORY_MANAGE',  'Create/edit any factory/vendor'),
    ('FACTORY_APPROVE_FOR_BUYER', 'Manage factory-buyer approval status');

-- SUPER_ADMIN already has every permission via the Phase-1 cross-join seed
-- pattern — re-apply it so it also covers these newly inserted rows.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN'
  AND p.code IN ('BUYER_VIEW','BUYER_MANAGE','BUYER_MANAGE_OWN','FACTORY_VIEW','FACTORY_MANAGE','FACTORY_APPROVE_FOR_BUYER');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER')
  AND p.code IN ('BUYER_VIEW','BUYER_MANAGE','FACTORY_VIEW','FACTORY_MANAGE','FACTORY_APPROVE_FOR_BUYER');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SENIOR_MERCHANDISER'
  AND p.code IN ('BUYER_VIEW','BUYER_MANAGE','FACTORY_VIEW','FACTORY_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'JUNIOR_MERCHANDISER'
  AND p.code IN ('BUYER_VIEW','BUYER_MANAGE_OWN','FACTORY_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE',
                  'ACCOUNTS_FINANCE','MANAGEMENT_VIEWER')
  AND p.code IN ('BUYER_VIEW','FACTORY_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'FACTORY_COORDINATOR'
  AND p.code IN ('FACTORY_VIEW');
