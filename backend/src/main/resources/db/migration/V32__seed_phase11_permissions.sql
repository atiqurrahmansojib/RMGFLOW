-- Phase 11: permission codes for financial tracking and claims (Document 5.2).

INSERT INTO permissions (code, description) VALUES
    ('FINANCIAL_VIEW',   'View order profitability, receivables, payables'),
    ('FINANCIAL_MANAGE', 'Record payments, manage receivables/payables'),
    ('CLAIM_VIEW',       'View claims/disputes'),
    ('CLAIM_MANAGE',     'Raise and resolve claims/disputes');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SUPER_ADMIN' AND p.code IN ('FINANCIAL_VIEW','FINANCIAL_MANAGE','CLAIM_VIEW','CLAIM_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD','GENERAL_MANAGER') AND p.code IN ('FINANCIAL_VIEW','FINANCIAL_MANAGE','CLAIM_VIEW','CLAIM_MANAGE');

-- Document 5.1/7: Accounts/Finance owns the financial ledger; merchandising
-- raises/tracks claims against orders they manage but doesn't see full financial detail by default.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'ACCOUNTS_FINANCE' AND p.code IN ('FINANCIAL_VIEW','FINANCIAL_MANAGE','CLAIM_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'SENIOR_MERCHANDISER' AND p.code IN ('CLAIM_VIEW','CLAIM_MANAGE','FINANCIAL_VIEW');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('JUNIOR_MERCHANDISER','COMMERCIAL_EXECUTIVE') AND p.code IN ('CLAIM_VIEW','CLAIM_MANAGE');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'MANAGEMENT_VIEWER' AND p.code IN ('FINANCIAL_VIEW','CLAIM_VIEW');
