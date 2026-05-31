# Backup Container for MilkyWay Test Environment

## Overview
The backup container performs database dumps for MariaDB, PostgreSQL and MongoDB. Dumps are written to `/backups` inside the container and mapped to the host `./backups` directory.

## Features
- Automated database dumps for MariaDB, PostgreSQL and MongoDB.
- Weekly catch-up on container start (ensures at least one backup per week for test environments).
- Cron-based scheduling (default daily at 03:00 UTC, configurable).
- Local retention and optional Restic integration for offsite encrypted backups.

## Components
- `Dockerfile` — builds the backup image.
- `entrypoint.sh` — prepares environment and starts cron/foreground process.
- `run_backups.sh` — performs the dumps and optionally runs Restic.
- `rotate.sh` — prunes old files according to `KEEP_DAYS`.

## Configuration
Configure credentials in `env/db/*.env` (or the env files referenced in `docker-compose.yml`):

- MariaDB: `MARIADB_HOST`, `MARIADB_PORT`, `MARIADB_USER`, `MARIADB_PASSWORD`, `MARIADB_DATABASE`
- PostgreSQL: `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- MongoDB: `MONGO_HOST`, `MONGO_PORT`, `MONGO_USER`, `MONGO_PASSWORD`, `MONGO_DB`

For Restic, use `env/backup/restic.env` and keep `RESTIC_PASSWORD` secret (prefer Docker secrets or a protected file).

## PostgreSQL: permissions & best practice
`pg_dump` requires read access to tables and sequences. Recommended approaches:

1. Grant privileges during database initialization (recommended):

   Run as superuser or database owner:

   ```sql
   CREATE ROLE backup LOGIN PASSWORD 'REPLACE_WITH_STRONG_PASSWORD';

   -- run inside the target database (or as superuser with -d)
   GRANT CONNECT ON DATABASE exampledb TO backup;
   GRANT USAGE ON SCHEMA public TO backup;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
   GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO backup;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO backup;
   ```

2. Apply grants to existing databases (one-time):

   Example (host):

   ```bash
   for db in $(docker exec -i milky-test-postgres psql -U milky_user -d postgres -At -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;"); do
     docker exec -i milky-test-postgres psql -U milky_user -d "$db" -c "GRANT USAGE ON SCHEMA public TO backup;"
     docker exec -i milky-test-postgres psql -U milky_user -d "$db" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;"
     docker exec -i milky-test-postgres psql -U milky_user -d "$db" -c "GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO backup;"
     docker exec -i milky-test-postgres psql -U milky_user -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;"
     docker exec -i milky-test-postgres psql -U milky_user -d "$db" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO backup;"
   done
   ```

3. Optional: idempotent grants inside `run_backups.sh`

   If the backup user defined in `POSTGRES_USER` can grant privileges, you can add an idempotent grant step at the start of `run_backups.sh` to ensure rights are present before each dump.

Notes:
- Prefer granting minimal privileges (SELECT + sequence USAGE).
- Use `ALTER DEFAULT PRIVILEGES` as the role that creates objects so future tables/sequences inherit backup access.

## Usage
Service name: `backup-test` in the repository `docker-compose.yml`.

Start the service (build if needed):
```bash
docker compose up -d --build
```

Trigger a manual backup:
```bash
docker compose exec backup-test /usr/local/bin/run_backups.sh
```

Weekly catch-up: `entrypoint.sh` triggers a backup at container start if a weekly stamp is missing.

## Restoration
- MariaDB: `gunzip -c file.sql.gz | mysql -uUSER -pPASSWORD DB`
- PostgreSQL: `gunzip -c file.sql.gz | psql -U user -d targetdb`
- MongoDB: `mongorestore --archive=file.archive.gz --gzip --db targetdb`

## Security
- Do not commit plain-text passwords to the repo.
- Prefer Docker secrets or protected env files for sensitive data.
- Restrict filesystem permissions on `./backups` on the host.

## Restic
See `env/backup/restic.env.example` for Restic configuration. Do not commit real credentials.

## Change note
If you rely on automated backups, ensure the `backup` role has SELECT and sequence USAGE on each database (or add grants to DB init scripts) so `pg_dump` can include table data and sequences.
