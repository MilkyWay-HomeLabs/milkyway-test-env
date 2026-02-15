#!/bin/bash
set -euo pipefail

# Entrypoint: writes the cron file and runs cron in the foreground (or execs the given command)
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"
CRON_FILE="/etc/cron.d/mw-backup"
LOG_DIR="/var/log/mw-backup"
LOG_FILE="${LOG_DIR}/backup.log"

# Ensure the log directory exists before cron starts writing
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

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

# If CMD is "foreground", run cron in the foreground; otherwise execute the provided command
if [[ "${1:-}" == "foreground" ]]; then
  exec cron -f
else
  exec "$@"
fi
