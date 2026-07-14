# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-07-14

Merged this repository with the deployed environment at
`infrastructure/docker/test`, which is now the single source of truth and the git
checkout itself. See `docs/MIGRATION.md`.

### Added
- **`auth-net`** (172.23.0.0/24, `internal: true`) — carries Andromeda and Nebula only.
  Membership of this network is what enforces "only Nebula may talk to the authorization
  server"; it is no longer a convention that has to be policed in review.
- `docs/ARCHITECTURE.md` (networks, IP plan, communication matrix), `docs/NAMING.md`,
  `docs/SECRETS.md`, `docs/MIGRATION.md`.
- `docs/future/` — reserved IPs, naming and paste-ready compose blocks for **element**,
  **racer** and **puzzel** (rest + front + game each).
- A pre-migration backup: logical dumps of all three databases, tarballs of all seven
  named volumes, and per-table row counts, taken without stopping a single container.

### Changed
- **Container naming is now `<app>-<role>-test` throughout.** The compose service key, the
  `container_name` and the DNS name are the same string — previously they differed, so
  `docker ps` showed `milky-test-mariadb` while every connection string said
  `mariadb-test`.
- **IP addressing is deterministic**: `.2` proxy, `.3–.9` infrastructure, `.30s`
  databases, then one 10-address block per app (`rest` = base, `front` = base+1,
  `game` = base+2), with the same last octet on every network a container joins.
- **Andromeda has no public route.** It was exposed at `/andromeda` and reachable by every
  backend; it is now off the `proxy` network entirely.
- Front-end and game containers are on `proxy` only — they have no route to any database.
- `.gitignore` now denies secrets **by pattern** (`*.env`, `env/**/*.properties`, with
  `*.example` re-admitted) instead of enumerating filenames. Enumeration is how
  `env/nginx/chess/.env` slipped through and how real credentials reached a public repo.
- `sql/postgres/000_create_databases_and_users.sql` and `sql/mongo/000_init_puzzel.js` no
  longer contain literal passwords.

### Security
- Every credential previously committed to this **public** repository is considered
  compromised and is being rotated — including a working **Gmail app password**, the
  shared `APP_JWT_SECRET`, and all database passwords. Git history has been purged, but
  that does not un-leak anything: rotation is the only fix. See `docs/SECRETS.md`.

### Known deviations
- `chess-rest-test` still calls Andromeda directly and therefore still holds `auth-net`
  membership. Removing it is a one-block change, blocked on Chess authenticating through
  Nebula. Tracked in `docs/ARCHITECTURE.md`.
- Renamed containers carry transitional DNS aliases for their old names, so that
  `dynamic.yml`, the properties files and `prometheus.yml` keep resolving during the
  rename. Remove them once those files are updated.

## [1.6.1] - 2026-07-04

### Changed
- Documented Hacman FE-4 deployment fix for frontend container environment after missing remote `docker compose up`.
- Added required configuration for `hacman-front-test`: `TrustSelfSignedCertificates=true` (recommended) or `HacmanApiInternalUrl=http://hacman-rest-test:8080/hacman/api/`.
- Clarified this is a container env change and does not require Traefik dynamic routing updates.

## [1.6.0] - 2026-05-30

### Added
- Integrated **Hacman** application components: `hacman-rest-test` (Kestrel), `hacman-front-test` (Kestrel), and `hacman-game-app` (Nginx).
- Added new environment variable examples for Hacman services: `env/kestrel/hacman/back/.env.example` and `env/nginx/hacman/.env.example`.
- Configured Traefik routing rules for Hacman API and Game application.

### Changed
- Updated Hacman Swagger routing to use `/hacman/swagger` instead of root `/swagger`.
- Updated Hacman Game routing to use `/hacman/game` instead of `/hacman/app`.
- Updated `README.md` and project documentation to version 1.6.0.
- Standardized all documentation to English.

## [1.5.0] - 2026-04-29

### Added
- Added new database configurations for PostgreSQL: `test_players` and `test_hacman` with dedicated users.
- Added environment variables for Nebula frontend in `.env.example` (`VITE_RESOURCES_DOMAIN`, `PLAYWRIGHT_IGNORE_HTTPS`, `PLAYWRIGHT_BASE_URL`).
- Added routing rules for development environment of Nebula and Andromeda applications in Traefik.

### Changed
- Updated Traefik configuration to support path-based routing for development environments (`/dev/nebula`, `/dev/andromeda`).
- Cleaned up `docker-compose.yml` for better readability.

## [1.4.0] - 2026-04-06

### Added
- Added `Milkyway` certificate support in `docker-compose.yml` with automatic import into the Java keystore.
- Added `.env.example` for environment configuration.
- Added routing rules for Swagger UI and API documentation paths for `nebula-rest-api` in Traefik's `dynamic.yml`.

### Changed
- Updated IPv4 address assignments for `proxy` and `internal` networks in `docker-compose.yml`.
- Refined `nebula-front-app` Dockerfile build process and environment configuration.
- Updated `NEBULA_FRONT_APP_URL` and cookie domain settings in `andromeda-authorization.properties.example`.
- Transitioned to path-based routing under `milkyway.test` domain, replacing previous subdomain structure (`*.test.milkyway`).
- Updated `PROJECT_DOCUMENTATION.md` and `README.md` to reflect the new domain structure and endpoints.

## [1.3.0] - 2026-03-05

### Changed
- Major refactoring of `test_andromeda` database schema, including tables for users, roles, and token management (access, refresh, confirmation).
- Refreshed seed data for `test_andromeda` database with a focus on user and token management.
- Updated `nebula-rest-api` application to a newer version (`nebula-rest-api##latest.war`).
- Updated system architecture diagram for the `test_andromeda` database model.

### Added
- New `refresh_token_incidents` table for tracking token security events.
- Added session expiration and encryption key properties to `andromeda-authorization.properties.example`.

## [1.2.0] - 2026-02-15

### Added
- Integrated **Nebula** application components into the test environment.
- Added `nebula-rest-test` container for the Nebula REST API.
- Added `nebula-front-test` container (Nginx) for the Nebula frontend application.
- Configured Traefik routing for Nebula (test and dev environments) in `dynamic.yml`.
- Updated system architecture diagram to include Nebula components.

## [1.1.0] - 2026-02-15

### Added
- Integrated backup service (`backup-test`) for automated database dumps (MariaDB, PostgreSQL, MongoDB).
- **Weekly "catch-up" backup**: The service now automatically triggers a backup on container start if it's the first run of the week. This ensures data safety even if the test environment is not running 24/7.
- Support for encrypted offsite backups using Restic.
- Automated backup rotation and retention policy.
- Detailed documentation for backup configuration and restoration in `backup/README.md`.
- Visual representation of the backup service in the system architecture diagram.

### Fixed
- Corrected typo in `README.md` environment configuration instructions (`cp .env.example .env`).

## [1.0.0] - 2026-02-15

### Added
- Initial release of the MilkyWay Test Environment.
- Core infrastructure using Docker Compose.
- Traefik reverse proxy with HTTPS support and dashboard.
- Monitoring stack: Prometheus, Grafana, Loki, Promtail, and Node Exporter.
- Databases: MariaDB, PostgreSQL, and MongoDB.
- Application servers: Tomcat (Andromeda) and Nginx (Fileserver).
- Automated database initialization with SQL scripts.
- Technical documentation in `README.md` and `PROJECT_DOCUMENTATION.md`.
