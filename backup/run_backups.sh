#!/bin/bash
set -euo pipefail

# Improved backup script: local restic init, run restic backup, then prune old local dumps
# Expected env vars: MARIADB_*, POSTGRES_*, MONGO_*, BACKUP_DIR, KEEP_DAYS, RESTIC_REPOSITORY, RESTIC_PASSWORD, RESTIC_FORGET_ARGS

MARIADB_HOST=${MARIADB_HOST:-milky-test-mariadb}
MARIADB_PORT=${MARIADB_PORT:-3306}
MARIADB_USER=${MARIADB_USER:-}
MARIADB_PASSWORD=${MARIADB_PASSWORD:-}
MARIADB_DATABASE=${MARIADB_DATABASE:-}

POSTGRES_HOST=${POSTGRES_HOST:-milky-test-postgres}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
POSTGRES_DB=${POSTGRES_DB:-}

MONGO_HOST=${MONGO_HOST:-milky-test-mongo}
MONGO_PORT=${MONGO_PORT:-27017}
MONGO_USER=${MONGO_USER:-${MONGO_INITDB_ROOT_USERNAME:-}}
MONGO_PASSWORD=${MONGO_PASSWORD:-${MONGO_INITDB_ROOT_PASSWORD:-}}
MONGO_DB=${MONGO_DB:-${MONGO_INITDB_DATABASE:-}}

BACKUP_DIR=${BACKUP_DIR:-/backups}
KEEP_DAYS=${KEEP_DAYS:-28}
TIMESTAMP=$(date +%F_%H-%M-%S)

mkdir -p "$BACKUP_DIR/mariadb" "$BACKUP_DIR/postgres" "$BACKUP_DIR/mongo" "$BACKUP_DIR/logs"

log(){ echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a "$BACKUP_DIR/logs/backup-$TIMESTAMP.log"; }

# --- MariaDB ---
if [ -n "${MARIADB_HOST:-}" ]; then
  log "Starting MariaDB backup (host=$MARIADB_HOST port=$MARIADB_PORT db=${MARIADB_DATABASE:-<all>})"
  if [ -z "${MARIADB_DATABASE:-}" ]; then
    DB_OPT="--all-databases"
  else
    DB_OPT="--databases $MARIADB_DATABASE"
  fi
  if [ -z "$MARIADB_USER" ]; then
    log "MARIADB_USER empty — mysqldump may fail"
  fi
  mysqldump --single-transaction --quick --lock-tables=false -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_USER" -p"$MARIADB_PASSWORD" $DB_OPT \
    | gzip > "$BACKUP_DIR/mariadb/mariadb-$TIMESTAMP.sql.gz"
  log "MariaDB backup finished"
else
  log "MARIADB_HOST not set, skipping MariaDB backup"
fi

# --- PostgreSQL ---
if [ -n "${POSTGRES_HOST:-}" ]; then
  log "Starting PostgreSQL backup (host=$POSTGRES_HOST port=$POSTGRES_PORT db=${POSTGRES_DB:-<all>})"
  export PGPASSWORD="${POSTGRES_PASSWORD:-}"
  if [ -z "${POSTGRES_DB:-}" ]; then
    pg_dumpall -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" | gzip > "$BACKUP_DIR/postgres/postgres-all-$TIMESTAMP.sql.gz"
  else
    pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$BACKUP_DIR/postgres/postgres-$POSTGRES_DB-$TIMESTAMP.sql.gz"
  fi
  unset PGPASSWORD
  log "PostgreSQL backup finished"
else
  log "POSTGRES_HOST not set, skipping PostgreSQL backup"
fi

# --- MongoDB ---
if [ -n "${MONGO_HOST:-}" ]; then
  log "Starting MongoDB backup (host=$MONGO_HOST port=$MONGO_PORT db=${MONGO_DB:-<all>})"
  if [ -z "${MONGO_DB:-}" ]; then
    MONGO_DB_OPT="--archive"
  else
    MONGO_DB_OPT="--archive --db ${MONGO_DB}"
  fi
  MONGO_AUTH=""
  if [ -n "${MONGO_USER:-}" ]; then
    MONGO_AUTH="--username ${MONGO_USER} --password ${MONGO_PASSWORD} --authenticationDatabase admin"
  fi
  mongodump --host "$MONGO_HOST" --port "$MONGO_PORT" $MONGO_AUTH $MONGO_DB_OPT --gzip > "$BACKUP_DIR/mongo/mongo-$TIMESTAMP.archive.gz"
  log "MongoDB backup finished"
else
  log "MONGO_HOST not set, skipping MongoDB backup"
fi

date -u +%Y-%m-%dT%H:%M:%SZ > "$BACKUP_DIR/last_success"
log "All configured backups finished"

# --- RESTIC (optional) ---
if [ -n "${RESTIC_REPOSITORY:-}" ]; then
  if [ -z "${RESTIC_PASSWORD:-}" ]; then
    log "RESTIC_REPOSITORY set but RESTIC_PASSWORD empty"
  fi
  export RESTIC_PASSWORD="${RESTIC_PASSWORD:-}"

  # If local repo (starts with /) and not initialized, initialize it
  if [[ "$RESTIC_REPOSITORY" == /* ]]; then
    if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
      log "Initializing local restic repository at $RESTIC_REPOSITORY"
      mkdir -p "$RESTIC_REPOSITORY"
      restic -r "$RESTIC_REPOSITORY" init || log "restic init failed"
    fi
  fi

  log "Running restic backup"
  restic -r "$RESTIC_REPOSITORY" backup "$BACKUP_DIR" || log "restic backup failed"

  # If you want a restic retention policy, set RESTIC_FORGET_ARGS, e.g.
  # RESTIC_FORGET_ARGS="--keep-daily 7 --keep-weekly 4 --keep-monthly 6"
  if [ -n "${RESTIC_FORGET_ARGS:-}" ]; then
    log "Running restic forget ${RESTIC_FORGET_ARGS} --prune"
    # Split on spaces intentionally; keep it controlled via env files.
    read -r -a FORGET_ARGS <<< "${RESTIC_FORGET_ARGS}"
    restic -r "$RESTIC_REPOSITORY" forget "${FORGET_ARGS[@]}" --prune || log "restic forget/prune failed"
  fi
fi

# --- Local retention (remove old dumps; exclude logs and any local restic repo) ---
# By default, prune only the dump directories, not the whole BACKUP_DIR.
PRUNE_PATHS=("$BACKUP_DIR/mariadb" "$BACKUP_DIR/postgres" "$BACKUP_DIR/mongo")
for p in "${PRUNE_PATHS[@]}"; do
  if [ -d "$p" ]; then
    find "$p" -type f -mtime +"$KEEP_DAYS" -print -delete
  fi
done
log "Old local backups pruned (>$KEEP_DAYS days)"

log "Backup script finished"
