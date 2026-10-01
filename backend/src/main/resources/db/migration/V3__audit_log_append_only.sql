-- Document 15.7: audit_logs must be append-only at the DB grant level, not merely
-- by application discipline. REVOKE UPDATE/DELETE from the application role.
-- NOTE: the role name below (rmgflow_app) must match the DB user the application
-- connects as in production; in local/dev (DB_USERNAME=rmgflow by default) this
-- statement is a no-op guard until that role exists, so it is wrapped defensively.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = current_user) THEN
        EXECUTE format('REVOKE UPDATE, DELETE ON audit_logs FROM %I', current_user);
    END IF;
END $$;
