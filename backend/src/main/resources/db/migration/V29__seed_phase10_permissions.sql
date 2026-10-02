-- Phase 10: permission codes for shipment/document management (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('SHIPMENT_VIEW',               'View shipments'),
    ('SHIPMENT_MANAGE',             'Create/edit shipments'),
    ('SHIPMENT_PARTIAL_AUTHORIZE',  'Authorize a partial shipment'),
    ('SHIPMENT_QUALITY_OVERRIDE',   'Create a shipment despite a failed/missing final inspection, with recorded reason'),
    ('DOCUMENT_VIEW',               'View commercial/compliance documents'),
    ('DOCUMENT_MANAGE',             'Upload/manage commercial/compliance documents');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN'
  AND p.code IN ('SHIPMENT_VIEW','SHIPMENT_MANAGE','SHIPMENT_PARTIAL_AUTHORIZE','SHIPMENT_QUALITY_OVERRIDE','DOCUMENT_VIEW','DOCUMENT_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD','GENERAL_MANAGER')
  AND p.code IN ('SHIPMENT_VIEW','SHIPMENT_MANAGE','SHIPMENT_PARTIAL_AUTHORIZE','SHIPMENT_QUALITY_OVERRIDE','DOCUMENT_VIEW','DOCUMENT_MANAGE');

-- Document 5.1/7: Commercial Executive owns day-to-day shipment/document work but
-- does not unilaterally authorize partial shipments or quality overrides (Owner/GM only).
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'COMMERCIAL_EXECUTIVE' AND p.code IN ('SHIPMENT_VIEW','SHIPMENT_MANAGE','DOCUMENT_VIEW','DOCUMENT_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SENIOR_MERCHANDISER','JUNIOR_MERCHANDISER') AND p.code IN ('SHIPMENT_VIEW','DOCUMENT_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','FACTORY_COORDINATOR','ACCOUNTS_FINANCE','MANAGEMENT_VIEWER')
  AND p.code IN ('SHIPMENT_VIEW','DOCUMENT_VIEW');
