#!/bin/bash
set -euo pipefail

BACKUP_DIR=${BACKUP_DIR:-/backups}
KEEP_DAYS=${KEEP_DAYS:-28}

# Prune only per-database dump folders to avoid touching logs, markers, or any restic repo under BACKUP_DIR.
PRUNE_PATHS=("$BACKUP_DIR/mariadb" "$BACKUP_DIR/postgres" "$BACKUP_DIR/mongo")

for p in "${PRUNE_PATHS[@]}"; do
  if [ -d "$p" ]; then
    find "$p" -type f -mtime +"$KEEP_DAYS" -print -delete
  fi
done
