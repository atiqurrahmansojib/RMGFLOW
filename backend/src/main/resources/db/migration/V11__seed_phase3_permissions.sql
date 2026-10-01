-- Phase 3: permission codes for inquiry/style/attachment management (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('INQUIRY_VIEW',    'View inquiries'),
    ('INQUIRY_MANAGE',  'Create/edit inquiries, factory candidates, win/loss'),
    ('STYLE_VIEW',      'View styles and revisions'),
    ('STYLE_MANAGE',    'Create styles and new revisions'),
    ('ATTACHMENT_MANAGE', 'Upload/download attachments on entities the user can already view');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN'
  AND p.code IN ('INQUIRY_VIEW','INQUIRY_MANAGE','STYLE_VIEW','STYLE_MANAGE','ATTACHMENT_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER', 'SENIOR_MERCHANDISER', 'JUNIOR_MERCHANDISER')
  AND p.code IN ('INQUIRY_VIEW','INQUIRY_MANAGE','STYLE_VIEW','STYLE_MANAGE','ATTACHMENT_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE',
                  'ACCOUNTS_FINANCE','MANAGEMENT_VIEWER','FACTORY_COORDINATOR')
  AND p.code IN ('STYLE_VIEW','ATTACHMENT_MANAGE');
