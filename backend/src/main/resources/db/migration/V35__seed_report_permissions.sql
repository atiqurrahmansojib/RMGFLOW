-- Reports module (Document 14 / Document 5.1 "Reports/dashboards" row).
-- REPORT_VIEW opens the reports catalog; each report additionally requires the
-- permission of the module it reads from (e.g. QUALITY_VIEW), so a role never sees
-- data through a report that it couldn't see through the module's own screens.
-- REPORT_VIEW_ALL waives that module check (Doc 5.1: Owner/GM/Management Viewer
-- have full report read). Financial reports always need REPORT_FINANCIAL_VIEW.
-- Row-level scoping is not a permission: roles other than Super Admin/Owner/GM/
-- Accounts/Management Viewer only see rows for their assigned buyers/factories
-- (assignments table, Doc 5.3), enforced in ReportService/ReportRegistry.

INSERT INTO permissions (code, description) VALUES
    ('REPORT_VIEW',           'Open the reports catalog and run reports for modules the user can view'),
    ('REPORT_VIEW_ALL',       'Run every non-financial report regardless of module permissions'),
    ('REPORT_FINANCIAL_VIEW', 'Run financial reports (costing margin, profitability, receivables/payables)');

-- Document 5.1: every role has (at least scoped) access to reports/dashboards.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SUPER_ADMIN','OWNER_MD','GENERAL_MANAGER','SENIOR_MERCHANDISER','JUNIOR_MERCHANDISER',
                  'SAMPLING_COORDINATOR','PRODUCTION_FOLLOWUP','QUALITY_INSPECTOR','COMMERCIAL_EXECUTIVE',
                  'ACCOUNTS_FINANCE','FACTORY_COORDINATOR','MANAGEMENT_VIEWER')
  AND p.code = 'REPORT_VIEW';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SUPER_ADMIN','OWNER_MD','GENERAL_MANAGER','MANAGEMENT_VIEWER')
  AND p.code = 'REPORT_VIEW_ALL';

-- Document 5.1 "Financial figures (cost, margin) visibility": Full for Owner/GM/Accounts,
-- own buyers for Senior Merchandiser (ReportService restricts every report row to the
-- user's BUYER assignments for merchandiser roles, so this grant never exposes other
-- buyers' margins). Junior Merchandiser: no margin. Management Viewer: "per Owner grant"
-- — deliberately NOT granted by default; an Owner can add it to the role later.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('SUPER_ADMIN','OWNER_MD','GENERAL_MANAGER','SENIOR_MERCHANDISER','ACCOUNTS_FINANCE')
  AND p.code = 'REPORT_FINANCIAL_VIEW';
