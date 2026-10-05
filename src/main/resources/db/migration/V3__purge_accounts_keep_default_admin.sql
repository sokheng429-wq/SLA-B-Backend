-- Migration V3: Remove all existing accounts (demo/seeded users).
-- After this runs, DataInitializer seeds the single default admin: Heng / 012793921.
-- Runs only once (Flyway), so accounts created later by the Admin are preserved.
DO $$
BEGIN
    IF to_regclass('public.sla_users') IS NOT NULL THEN
        DELETE FROM sla_users WHERE LOWER(username) <> 'heng';
    END IF;
END $$;
