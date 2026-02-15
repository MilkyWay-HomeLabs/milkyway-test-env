# MilkyWay Home Lab - Test Environment
**Version: 1.2.0**

This repository contains the test environment configuration for the MilkyWay project, based on Docker Compose.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Domain Configuration (/etc/hosts)](#local-domain-configuration-etchosts)
3. [TLS Certificates](#tls-certificates)
4. [Environment Configuration](#environment-configuration)
5. [Architecture and Containers](#architecture-and-containers)
6. [Backups](#backups)
7. [Changelog](#changelog)
8. [Starting the Environment](#starting-the-environment)
9. [License and Author](#license-and-author)

## Prerequisites
- Docker and Docker Compose installed.
- `openssl` (optional, for generating self-signed certificates).

## Local Domain Configuration (/etc/hosts)
To access the services using their domain names, add the following entries to your `/etc/hosts` file (on Linux/macOS) or `C:\Windows\System32\drivers\etc\hosts` (on Windows):

```text
127.0.0.1   traefik.test.milkyway
127.0.0.1   prometheus.test.milkyway
127.0.0.1   grafana.test.milkyway
127.0.0.1   resources.test.milkyway
127.0.0.1   andromeda.test.milkyway
127.0.0.1   andromeda.dev.milkyway
127.0.0.1   nebula.test.milkyway
127.0.0.1   nebula.dev.milkyway
```

## TLS Certificates
The environment uses HTTPS. You need to provide TLS certificates for Traefik.

1. Go to the `traefik/certs/` directory.
2. Follow the instructions in [traefik/certs/README.md](traefik/certs/README.md) to generate a self-signed certificate or provide your own.

Quick command to generate a test certificate:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout traefik/certs/milkyway.key \
  -out traefik/certs/milkyway.crt \
  -subj "/C=PL/ST=Test/L=Test/O=MilkyWay/CN=*.test.milkyway"
```

## Environment Configuration
Copy the `.env.example` file to `.env` and fill in the required variables (e.g., Traefik dashboard password).

```bash
cp .env.example .env
```

## Documentation and Architecture
Więcej szczegółów technicznych znajduje się w katalogu [docs/](docs/).

### Architecture and Containers
Detailed technical specification of containers, networks, and endpoints can be found in [docs/PROJECT_DOCUMENTATION.md](docs/PROJECT_DOCUMENTATION.md).

### Container Diagram
```mermaid
graph TD
    %% User Access
    User([fa:fa-user User / Browser]) -->|HTTPS 443| Traefik

    %% Main Proxy Component
    subgraph ProxyLayer ["fa:fa-shield-halved Edge Proxy & Routing"]
        Traefik[fa:fa-route Traefik Proxy]
    end

    %% Applications Layer
    subgraph AppLayer ["fa:fa-gears Applications"]
        TomcatAndromeda[fa:fa-code Tomcat - Andromeda]
        TomcatNebula[fa:fa-code Tomcat - Nebula]
        NebulaFront[fa:fa-desktop Nebula Frontend]
        Fileserver[fa:fa-file-code Fileserver - Nginx]
        AndromedaDev[fa:fa-flask Andromeda Dev]
    end

    %% Databases Layer
    subgraph DBLayer ["fa:fa-database Storage"]
        MariaDB[(fa:fa-database MariaDB)]
        Postgres[(fa:fa-database PostgreSQL)]
        Mongo[(fa:fa-database MongoDB)]
    end

    %% Monitoring Stack
    subgraph MonitoringLayer ["fa:fa-chart-line Monitoring & Observability"]
        Grafana[fa:fa-chart-column Grafana]
        Prometheus[fa:fa-gauge-high Prometheus]
        Loki[fa:fa-list-check Loki]
        NodeExporter[fa:fa-microchip Node Exporter]
        Promtail[fa:fa-conveyor-belt Promtail]
    end

    %% Connections
    Traefik -->|Routing| TomcatAndromeda
    Traefik -->|Routing| TomcatNebula
    Traefik -->|Routing| NebulaFront
    Traefik -->|Routing| Fileserver
    Traefik -->|Routing| AndromedaDev
    Traefik -->|Routing| Grafana
    Traefik -->|Routing| Prometheus

    TomcatAndromeda --> MariaDB
    TomcatNebula --> MariaDB

    Prometheus -->|Scrape| NodeExporter
    Prometheus -->|Scrape| TomcatAndromeda
    Prometheus -->|Scrape| TomcatNebula
    Promtail -->|Collect Logs| Loki
    Grafana -->|Query| Prometheus
    Grafana -->|Query| Loki

    backup-test --> MariaDB
    backup-test --> Postgres
    backup-test --> Mongo

    %% Styling
    classDef proxy fill:#f9f,stroke:#333,stroke-width:2px,color:#000;
    classDef app fill:#bbf,stroke:#333,stroke-width:1px,color:#000;
    classDef db fill:#bfb,stroke:#333,stroke-width:1px,color:#000;
    classDef monitor fill:#fbb,stroke:#333,stroke-width:1px,color:#000;

    class Traefik proxy;
    class TomcatAndromeda,TomcatNebula,NebulaFront,Fileserver,AndromedaDev app;
    class MariaDB,Postgres,Mongo db;
    class Grafana,Prometheus,Loki,NodeExporter,Promtail monitor;
```

## Backups
The environment includes an automated backup service (`backup-test`) that performs periodic dumps of all databases (MariaDB, PostgreSQL, MongoDB).

- **Backup Location**: Backups are stored in the `./backups` directory on the host.
- **Retention**: Old backups are automatically rotated.
- **Weekly Catch-up**: Since the test environment is not always on, a backup is automatically triggered on container start if one hasn't been run yet during the current week.
- **Manual Trigger**:
  ```bash
  docker compose exec backup-test /usr/local/bin/run_backups.sh
  ```
For detailed configuration and restoration instructions, see [docs/BACKUP_GUIDE.md](docs/BACKUP_GUIDE.md).

## Changelog
Detailed history of changes can be found in [docs/CHANGELOG.md](docs/CHANGELOG.md).

## Starting the Environment
To start all services:
```bash
docker compose up -d
```
The Traefik dashboard will be available at [https://traefik.test.milkyway](https://traefik.test.milkyway).

## License and Author
- **Author**: Szymon Derleta
- **License**: [Apache License 2.0](LICENSE)
