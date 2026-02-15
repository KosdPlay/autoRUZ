-- 1) создаём роли (app, readonly)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='app') THEN
    CREATE ROLE app LOGIN PASSWORD 'app_pass' CONNECTION LIMIT 20;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='readonly') THEN
    CREATE ROLE readonly LOGIN PASSWORD 'readonly_pass' CONNECTION LIMIT 20;
  END IF;
END$$;

-- 2) доступ к БД
GRANT CONNECT ON DATABASE autoru_db TO app, readonly;

-- 3) доступ к схеме
GRANT USAGE ON SCHEMA service TO app, readonly;

-- 4) таблицы: app CRUD, readonly только SELECT
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA service TO app;
GRANT SELECT ON ALL TABLES IN SCHEMA service TO readonly;

-- 5) последовательности (SERIAL)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA service TO app;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA service TO readonly;

-- 6) чтобы новые таблицы/seq тоже автоматически получали права
ALTER DEFAULT PRIVILEGES IN SCHEMA service
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;

ALTER DEFAULT PRIVILEGES IN SCHEMA service
  GRANT SELECT ON TABLES TO readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA service
  GRANT USAGE, SELECT ON SEQUENCES TO app;

ALTER DEFAULT PRIVILEGES IN SCHEMA service
  GRANT SELECT ON SEQUENCES TO readonly;