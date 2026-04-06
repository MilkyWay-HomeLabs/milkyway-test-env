# Changelog

All notable changes to this project will be documented in this file.

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
- Added `tomcat-test-nebula` container for the Nebula REST API.
- Added `nebula-front-app-test` container (Nginx) for the Nebula frontend application.
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
