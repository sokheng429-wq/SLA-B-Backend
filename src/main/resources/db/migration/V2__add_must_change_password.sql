-- Migration V2: Add must_change_password flag for user forced password reset flow
ALTER TABLE sla_users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;
