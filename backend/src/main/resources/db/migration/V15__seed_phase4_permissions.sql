-- Phase 4: permission codes for costing/quotation/approval (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('COSTING_VIEW',          'View costings (totals, not necessarily margin)'),
    ('COSTING_VIEW_MARGIN',   'View costing margin/profit figures'),
    ('COSTING_MANAGE',        'Create/edit draft costings and submit for approval'),
    ('COSTING_APPROVE',       'Approve or reject a submitted costing'),
    ('QUOTATION_VIEW',        'View quotations'),
    ('QUOTATION_MANAGE',      'Create/edit draft quotations, send to buyer'),
    ('QUOTATION_APPROVE',     'Record buyer approval/rejection of a quotation');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN'
  AND p.code IN ('COSTING_VIEW','COSTING_VIEW_MARGIN','COSTING_MANAGE','COSTING_APPROVE',
                  'QUOTATION_VIEW','QUOTATION_MANAGE','QUOTATION_APPROVE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER')
  AND p.code IN ('COSTING_VIEW','COSTING_VIEW_MARGIN','COSTING_MANAGE','COSTING_APPROVE',
                  'QUOTATION_VIEW','QUOTATION_MANAGE','QUOTATION_APPROVE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SENIOR_MERCHANDISER'
  AND p.code IN ('COSTING_VIEW','COSTING_VIEW_MARGIN','COSTING_MANAGE','COSTING_APPROVE',
                  'QUOTATION_VIEW','QUOTATION_MANAGE','QUOTATION_APPROVE');

-- Document 5.2 note: Junior Merchandiser margin visibility is off by default.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'JUNIOR_MERCHANDISER'
  AND p.code IN ('COSTING_VIEW','COSTING_MANAGE','QUOTATION_VIEW','QUOTATION_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'ACCOUNTS_FINANCE'
  AND p.code IN ('COSTING_VIEW','COSTING_VIEW_MARGIN','QUOTATION_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'MANAGEMENT_VIEWER'
  AND p.code IN ('COSTING_VIEW','QUOTATION_VIEW');
