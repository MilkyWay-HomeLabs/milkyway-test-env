#!/bin/bash
set -euo pipefail

GLOBAL_WAIT_TIMEOUT=${GLOBAL_WAIT_TIMEOUT:-60}

# Improved backup script: local restic init, run restic backup, then prune old local dumps
# Expected env vars: MARIADB_*, POSTGRES_*, MONGO_*, BACKUP_DIR, KEEP_DAYS, RESTIC_REPOSITORY, RESTIC_PASSWORD, RESTIC_FORGET_ARGS
# This variant uses MARIADB_BACKUP_USER / MARIADB_BACKUP_PASSWORD if set and always does --all-databases.

MARIADB_HOST=${MARIADB_HOST:-milky-test-mariadb}
MARIADB_PORT=${MARIADB_PORT:-3306}
MARIADB_USER=${MARIADB_BACKUP_USER:-$MARIADB_USER}
MARIADB_PASSWORD=${MARIADB_BACKUP_PASSWORD:-$MARIADB_PASSWORD}
MARIADB_DATABASE=${MARIADB_DATABASE:-}

POSTGRES_HOST=${POSTGRES_HOST:-milky-test-postgres}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_BACKUP_USER:-$POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_BACKUP_PASSWORD:-$POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB:-}

MONGO_HOST=${MONGO_HOST:-milky-test-mongo}
MONGO_PORT=${MONGO_PORT:-27017}
MONGO_USER=${MONGO_BACKUP_USER:-$MONGO_USER}
MONGO_PASSWORD=${MONGO_BACKUP_PASSWORD:-$MONGO_PASSWORD}
MONGO_DB=${MONGO_DB:-${MONGO_INITDB_DATABASE:-}}

BACKUP_DIR=${BACKUP_DIR:-/backups}
KEEP_DAYS=${KEEP_DAYS:-28}
TIMESTAMP=$(date +%F_%H-%M-%S)

log(){ echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a "$BACKUP_DIR/logs/backup-$TIMESTAMP.log"; }

# Resolve backup owner: prefer numeric UID/GID, then BACKUP_OWNER_USER in container, then detect host mount owner of BACKUP_DIR
if [ -n "${BACKUP_OWNER_UID:-}" ]; then
  BACKUP_OWNER_GID=${BACKUP_OWNER_GID:-$BACKUP_OWNER_UID}
  log "Using provided BACKUP_OWNER_UID=${BACKUP_OWNER_UID} BACKUP_OWNER_GID=${BACKUP_OWNER_GID}"
else
  if [ -n "${BACKUP_OWNER_USER:-}" ]; then
    if command -v id >/dev/null 2>&1 && id -u "$BACKUP_OWNER_USER" >/dev/null 2>&1; then
      BACKUP_OWNER_UID=$(id -u "$BACKUP_OWNER_USER")
      BACKUP_OWNER_GID=$(id -g "$BACKUP_OWNER_USER")
      log "Resolved BACKUP_OWNER_USER='$BACKUP_OWNER_USER' -> ${BACKUP_OWNER_UID}:${BACKUP_OWNER_GID}"
    else
      log "WARN: BACKUP_OWNER_USER='$BACKUP_OWNER_USER' not found in container, will try to detect host mount owner"
    fi
  fi

  # Fallback: detect owner of the mounted BACKUP_DIR (host owner visible from container)
  if [ -z "${BACKUP_OWNER_UID:-}" ]; then
    if [ -d "${BACKUP_DIR:-/backups}" ]; then
      owner=$(stat -c '%u:%g' "${BACKUP_DIR}" 2>/dev/null || true)
      if [ -n "$owner" ]; then
        uid=${owner%%:*}
        gid=${owner##*:}
        if [ -n "$uid" ]; then
          BACKUP_OWNER_UID=${BACKUP_OWNER_UID:-$uid}
          BACKUP_OWNER_GID=${BACKUP_OWNER_GID:-$gid}
          log "Detected host mount owner for ${BACKUP_DIR}: ${BACKUP_OWNER_UID}:${BACKUP_OWNER_GID}"
        fi
      fi
    else
      log "WARN: BACKUP_DIR ${BACKUP_DIR} not present; cannot auto-detect host owner"
    fi
  fi

  # Ensure GID mirrors UID if only UID set
  if [ -n "${BACKUP_OWNER_UID:-}" ] && [ -z "${BACKUP_OWNER_GID:-}" ]; then
    BACKUP_OWNER_GID=$BACKUP_OWNER_UID
  fi
fi

mkdir -p "$BACKUP_DIR/mariadb" "$BACKUP_DIR/postgres" "$BACKUP_DIR/mongo" "$BACKUP_DIR/logs"

# --- MariaDB ---
if [ -n "${MARIADB_HOST:-}" ]; then
  log "Starting MariaDB backup (host=$MARIADB_HOST port=$MARIADB_PORT) - backing up all databases"
  DB_OPT="--all-databases"

  if [ -z "$MARIADB_USER" ]; then
    log "MARIADB_USER empty — mysqldump may fail"
  fi

  # wait for MariaDB up (simple poll)
  WAIT_TIMEOUT=${MARIADB_WAIT_TIMEOUT:-$GLOBAL_WAIT_TIMEOUT}
  start_time=$(date +%s)
  while ! mysqladmin ping -h "$MARIADB_HOST" -u"${MARIADB_USER:-}" -p"${MARIADB_PASSWORD:-}" --silent >/dev/null 2>&1; do
    now=$(date +%s)
    if [ $((now - start_time)) -ge "$WAIT_TIMEOUT" ]; then
      log "MariaDB did not become ready after ${WAIT_TIMEOUT}s, attempting dump anyway"
      break
    fi
    sleep 2
  done

  TMPFILE="$BACKUP_DIR/mariadb/mariadb-$TIMESTAMP.sql.tmp"
  ERRFILE="$BACKUP_DIR/logs/mysqldump-$TIMESTAMP.err"

  if mysqldump --single-transaction --quick --lock-tables=false -h "$MARIADB_HOST" -P "$MARIADB_PORT" -u "$MARIADB_USER" -p"$MARIADB_PASSWORD" $DB_OPT > "$TMPFILE" 2> "$ERRFILE"; then
    gzip -c "$TMPFILE" > "$BACKUP_DIR/mariadb/mariadb-$TIMESTAMP.sql.gz"
    rm -f "$TMPFILE" "$ERRFILE"
    log "MariaDB backup finished: mariadb-$TIMESTAMP.sql.gz"
  else
    log "MariaDB backup FAILED. See $ERRFILE and tmp dump $TMPFILE for details"
    # keep tmp and err for inspection
  fi
else
  log "MARIADB_HOST not set, skipping MariaDB backup"
fi

# --- PostgreSQL ---
if [ -n "${POSTGRES_HOST:-}" ]; then
  log "Starting PostgreSQL backup (host=$POSTGRES_HOST port=$POSTGRES_PORT db=${POSTGRES_DB:-<all>})"
  export PGPASSWORD="${POSTGRES_PASSWORD:-}"

  # wait for Postgres to be ready (connect to 'postgres' database explicitly)
  WAIT_TIMEOUT=${POSTGRES_WAIT_TIMEOUT:-$GLOBAL_WAIT_TIMEOUT}
  start_time=$(date +%s)
  while ! psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -c '\q' >/dev/null 2>&1; do
    now=$(date +%s)
    if [ $((now - start_time)) -ge "$WAIT_TIMEOUT" ]; then
      log "Postgres did not become ready after ${WAIT_TIMEOUT}s, attempting dumps anyway"
      break
    fi
    sleep 2
  done

  if [ -n "${POSTGRES_DB:-}" ]; then
    # single database specified -> dump only that one
    TMPFILE="$BACKUP_DIR/postgres/postgres-$POSTGRES_DB-$TIMESTAMP.sql.tmp"
    ERRFILE="$BACKUP_DIR/logs/pgdump-$POSTGRES_DB-$TIMESTAMP.err"
    if pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$TMPFILE" 2> "$ERRFILE"; then
      gzip -c "$TMPFILE" > "$BACKUP_DIR/postgres/postgres-$POSTGRES_DB-$TIMESTAMP.sql.gz"
      rm -f "$TMPFILE" "$ERRFILE"
      log "Postgres dump finished: postgres-$POSTGRES_DB-$TIMESTAMP.sql.gz"
    else
      log "Postgres dump FAILED for $POSTGRES_DB. See $ERRFILE and tmp dump $TMPFILE for details"
    fi
  else
    # dump each non-template, connectable database
    DBS=$(psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -At -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;")
    # filter out system DBs (postgres, template0, template1)
    DBS=$(echo "$DBS" | tr ' ' '\n' | grep -vE '^(postgres|template0|template1)$' | tr '\n' ' ')
    if [ -z "${DBS}" ]; then
      log "No PostgreSQL databases found to dump, skipping PostgreSQL backup"
    else
      for db in $DBS; do
        log "Dumping postgres db: $db"
        TMPFILE="$BACKUP_DIR/postgres/postgres-$db-$TIMESTAMP.sql.tmp"
        ERRFILE="$BACKUP_DIR/logs/pgdump-$db-$TIMESTAMP.err"
        if pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db" > "$TMPFILE" 2> "$ERRFILE"; then
          gzip -c "$TMPFILE" > "$BACKUP_DIR/postgres/postgres-$db-$TIMESTAMP.sql.gz"
          rm -f "$TMPFILE" "$ERRFILE"
          log "Postgres dump finished: postgres-$db-$TIMESTAMP.sql.gz"
        else
          log "Postgres dump FAILED for $db. See $ERRFILE and tmp dump $TMPFILE for details"
          # keep files for inspection
        fi
      done
    fi
  fi

  unset PGPASSWORD
  log "PostgreSQL backup finished"
else
  log "POSTGRES_HOST not set, skipping PostgreSQL backup"
fi

# --- MongoDB ---
if [ -n "${MONGO_HOST:-}" ]; then
  log "Starting MongoDB backup (host=$MONGO_HOST port=$MONGO_PORT db=${MONGO_DB:-<all>})"

  WAIT_TIMEOUT=${MONGO_WAIT_TIMEOUT:-$GLOBAL_WAIT_TIMEOUT}
  start_time=$(date +%s)
  while ! mongo --host "$MONGO_HOST" --port "$MONGO_PORT" --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    now=$(date +%s)
    if [ $((now - start_time)) -ge "$WAIT_TIMEOUT" ]; then
      log "MongoDB did not become ready after ${WAIT_TIMEOUT}s, attempting dump anyway"
      break
    fi
    sleep 2
  done

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

# Ensure backup files have correct owner on the host (optional)
if [ -n "${BACKUP_OWNER_UID:-}" ]; then
  BACKUP_OWNER_GID=${BACKUP_OWNER_GID:-$BACKUP_OWNER_UID}
  chown -R "${BACKUP_OWNER_UID}:${BACKUP_OWNER_GID}" "$BACKUP_DIR" || true
  chmod -R u+rwX,g+rX,o-rw "$BACKUP_DIR" || true
  log "Adjusted ownership of $BACKUP_DIR to ${BACKUP_OWNER_UID}:${BACKUP_OWNER_GID}"
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
