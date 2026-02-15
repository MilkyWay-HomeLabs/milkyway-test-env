#!/bin/bash
set -euo pipefail

# Entrypoint: writes the cron file and runs cron in the foreground (or execs the given command)
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"
CRON_FILE="/etc/cron.d/mw-backup"
LOG_DIR="/var/log/mw-backup"
LOG_FILE="${LOG_DIR}/backup.log"

BACKUP_DIR="${BACKUP_DIR:-/backups}"
WEEKLY_STAMP_FILE="${BACKUP_DIR}/.mw-backup-weekly.stamp"

# Ensure the log directory exists before cron starts writing
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Ensure backup dir exists (for weekly stamp)
mkdir -p "$BACKUP_DIR"

# Basic hardening: reject empty schedule and any value containing newlines (prevents cronfile injection)
if [[ -z "${CRON_SCHEDULE}" ]] || [[ "${CRON_SCHEDULE}" == *$'\n'* ]] || [[ "${CRON_SCHEDULE}" == *$'\r'* ]]; then
  echo "Invalid CRON_SCHEDULE value" >&2
  exit 1
fi

# Create the cron entry that runs the backup script
cat > "$CRON_FILE" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

${CRON_SCHEDULE} root /usr/local/bin/run_backups.sh >> ${LOG_FILE} 2>&1
EOF

chown root:root "$CRON_FILE"
chmod 0644 "$CRON_FILE"

# Run weekly backup once per week on container start (catches up if PC was off)
current_week="$(date -u +%G-%V)"
last_week=""
if [[ -f "$WEEKLY_STAMP_FILE" ]]; then
  last_week="$(cat "$WEEKLY_STAMP_FILE" 2>/dev/null || true)"
fi

if [[ "$last_week" != "$current_week" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) weekly-on-start: running backup (week=$current_week, last=$last_week)" >> "$LOG_FILE"
  /usr/local/bin/run_backups.sh >> "$LOG_FILE" 2>&1 || echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) weekly-on-start: backup failed" >> "$LOG_FILE"
  echo "$current_week" > "$WEEKLY_STAMP_FILE"
  chmod 0644 "$WEEKLY_STAMP_FILE" || true
else
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) weekly-on-start: already done this week ($current_week), skipping" >> "$LOG_FILE"
fi

# If CMD is "foreground", run cron in the foreground; otherwise execute the provided command
if [[ "${1:-}" == "foreground" ]]; then
  exec cron -f
else
  exec "$@"
fi
