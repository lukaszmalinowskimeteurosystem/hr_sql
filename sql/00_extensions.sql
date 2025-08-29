-- 00_extensions.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS hstore;

DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
      CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'postgres';
   END IF;
END$$;
