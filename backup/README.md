# Backup Container for MilkyWay Test Environment

## Overview
The backup container performs database dumps for MariaDB, PostgreSQL, and MongoDB. These dumps are saved in the `/backups` directory (mapped to the host's `./backups` directory).

## Main Components
- `Dockerfile`: Defines the backup container image.
- `entrypoint.sh`: Sets up the cron job and starts the `cron` daemon in the foreground.
- `run_backups.sh`: Executes the database dumps and optionally triggers `restic` for offsite backups if configured.
- `rotate.sh`: Cleans up backup files older than the specified `KEEP_DAYS`.

## Configuration
1. **Database Credentials**: Configure the environment files in `env/db/*.env` with the necessary credentials. The container expects the following variables:
   - **MariaDB**: `MARIADB_HOST`, `MARIADB_PORT`, `MARIADB_USER`, `MARIADB_PASSWORD`, `MARIADB_DATABASE`
   - **PostgreSQL**: `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
   - **MongoDB**: `MONGO_HOST`, `MONGO_PORT`, `MONGO_USER`, `MONGO_PASSWORD`, `MONGO_DB`

2. **Restic (Optional)**: If you wish to send backups to an encrypted Restic repository:
   - Configure `env/backup/restic.env`.
   - Provide the repository password in `env/backup/restic_pw` (recommended using Docker secrets or a secure file).

## Usage
The backup service is integrated into the main `docker-compose.yml` file as `backup-test`.

### Starting the Service
To build and start the backup service along with the rest of the environment:
```bash
docker compose up -d --build
```

### Manual Backup Trigger
You can trigger a backup manually without waiting for the cron job:
```bash
docker compose exec backup-test /usr/local/bin/run_backups.sh
```

## Restoration Guide
- **MariaDB**: `gunzip -c file.sql.gz | mysql -uUSER -pPASSWORD DB`
- **PostgreSQL**: `gunzip -c file.sql.gz | psql -U user -d targetdb`
- **MongoDB**: `mongorestore --archive=file.archive.gz --gzip --db targetdb`

## Security Considerations
- **Avoid plain-text passwords**: Do not store passwords in plain text within the repository.
- **Use Environment Files/Secrets**: Use `.env` files with restricted permissions or Docker secrets for sensitive information.
- **Restricted Access**: Ensure the `./backups` directory on the host has appropriate permissions.

## Restic Integration
The `env/backup/restic.env.example` file provides a template for Restic configuration. Ensure you do not commit actual passwords or sensitive keys to the repository.
