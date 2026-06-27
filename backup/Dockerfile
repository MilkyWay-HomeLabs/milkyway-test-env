FROM mongo:8 AS mongo_tools

FROM debian:bookworm-slim

ARG RESTIC_VERSION=0.18.1
ARG TARGETARCH

# Base tools + SQL clients
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      cron \
      bash \
      curl \
      gzip \
      bzip2 \
      gnupg \
      wget \
      default-mysql-client; \
    rm -rf /var/lib/apt/lists/*

# MongoDB client tools (mongodump/mongorestore) copied from official mongo image
COPY --from=mongo_tools /usr/bin/mongodump /usr/local/bin/mongodump
COPY --from=mongo_tools /usr/bin/mongorestore /usr/local/bin/mongorestore

# Add PostgreSQL APT repository and install postgresql-client-16 (compatible with Debian bookworm)
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg wget ca-certificates; \
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql-client-16; \
    rm -rf /var/lib/apt/lists/*

# Install restic (multi-arch)
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64) RESTIC_ARCH="amd64" ;; \
      arm64) RESTIC_ARCH="arm64" ;; \
      *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${RESTIC_ARCH}.bz2" -o /tmp/restic.bz2; \
    bunzip2 /tmp/restic.bz2; \
    install -m 0755 /tmp/restic /usr/local/bin/restic; \
    rm -f /tmp/restic

## Directory for backups
RUN mkdir -p /backups /var/log/mw-backup
WORKDIR /usr/local/bin

## Scripts
COPY run_backups.sh /usr/local/bin/run_backups.sh
COPY rotate.sh /usr/local/bin/rotate.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/run_backups.sh /usr/local/bin/rotate.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["foreground"]
