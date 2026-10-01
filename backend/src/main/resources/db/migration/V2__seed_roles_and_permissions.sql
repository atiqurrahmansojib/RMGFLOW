-- Phase 1 (P1-T2): seed the 12 roles (Document 5.1) and initial permission catalog (Document 5.2, ADR-05).
-- Permission-to-role mapping here is the Phase-1 slice only (identity/admin concerns);
-- module-specific permissions (ORDER_CREATE, COSTING_APPROVE, etc.) are seeded in the
-- migration that introduces each module (Phase 2+), per ADR-05's "known, bounded catalog" decision.

INSERT INTO roles (name, description) VALUES
    ('SUPER_ADMIN',              'System configuration, user/role management'),
    ('OWNER_MD',                 'Managing Director / Owner'),
    ('GENERAL_MANAGER',          'Cross-buyer/cross-factory operational oversight'),
    ('SENIOR_MERCHANDISER',      'Owns buyer relationships, costing/quotation/order management'),
    ('JUNIOR_MERCHANDISER',      'Executes under senior merchandiser'),
    ('SAMPLING_COORDINATOR',     'Manages sample lifecycle'),
    ('PRODUCTION_FOLLOWUP',      'Factory-based daily production entry, T&A updates'),
    ('QUALITY_INSPECTOR',        'Inspection records, defects, CAPA'),
    ('COMMERCIAL_EXECUTIVE',     'Shipment and document management'),
    ('ACCOUNTS_FINANCE',         'Payment/receivable/payable tracking'),
    ('FACTORY_COORDINATOR',      'Liaison for one or more assigned factories'),
    ('MANAGEMENT_VIEWER',        'Read-only dashboards/reports');

INSERT INTO permissions (code, description) VALUES
    ('USER_MANAGE',            'Create, edit, deactivate users'),
    ('ROLE_MANAGE',            'Manage roles and permission mappings'),
    ('ASSIGNMENT_MANAGE',      'Manage user-to-buyer / user-to-factory assignments'),
    ('AUDIT_LOG_VIEW',         'View the system audit log'),
    ('MASTER_DATA_MANAGE',     'Manage reference/master data (currencies, seasons, etc.)');

-- SUPER_ADMIN gets every Phase-1 permission.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.name = 'SUPER_ADMIN';

-- OWNER_MD and GENERAL_MANAGER can view audit log and manage assignments; not full admin.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('OWNER_MD', 'GENERAL_MANAGER')
  AND p.code IN ('AUDIT_LOG_VIEW', 'ASSIGNMENT_MANAGE', 'MASTER_DATA_MANAGE');
