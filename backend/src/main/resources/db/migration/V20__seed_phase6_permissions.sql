-- Phase 6: permission codes for order management (Document 5.2 matrix).

INSERT INTO permissions (code, description) VALUES
    ('ORDER_VIEW',                'View orders'),
    ('ORDER_CREATE',              'Confirm a new order'),
    ('ORDER_AMEND_REQUEST',       'Request an order amendment (qty/price/date/destination)'),
    ('ORDER_AMEND_APPROVE',       'Approve or reject a requested order amendment'),
    ('ORDER_CANCEL_APPROVE',      'Approve order cancellation'),
    ('ORDER_FACTORY_OVERRIDE',    'Assign a factory not yet buyer-approved, with recorded reason');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN'
  AND p.code IN ('ORDER_VIEW','ORDER_CREATE','ORDER_AMEND_REQUEST','ORDER_AMEND_APPROVE','ORDER_CANCEL_APPROVE','ORDER_FACTORY_OVERRIDE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER')
  AND p.code IN ('ORDER_VIEW','ORDER_CREATE','ORDER_AMEND_REQUEST','ORDER_AMEND_APPROVE','ORDER_CANCEL_APPROVE','ORDER_FACTORY_OVERRIDE');

-- Document 5.2: Senior Merchandiser creates orders and REQUESTS amendments, but does
-- not unilaterally approve amendments or cancellations (Owner/GM authority only).
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SENIOR_MERCHANDISER'
  AND p.code IN ('ORDER_VIEW','ORDER_CREATE','ORDER_AMEND_REQUEST');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'JUNIOR_MERCHANDISER' AND p.code IN ('ORDER_VIEW','ORDER_AMEND_REQUEST');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE',
                  'ACCOUNTS_FINANCE','MANAGEMENT_VIEWER','FACTORY_COORDINATOR')
  AND p.code = 'ORDER_VIEW';
