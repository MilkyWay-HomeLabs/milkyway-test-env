# MilkyWay Home Lab - Test Environment

This repository contains the test environment configuration for the MilkyWay project, based on Docker Compose.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Domain Configuration (/etc/hosts)](#local-domain-configuration-etchosts)
3. [TLS Certificates](#tls-certificates)
4. [Environment Configuration](#environment-configuration)
5. [Architecture and Containers](#architecture-and-containers)
6. [Starting the Environment](#starting-the-environment)

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

## Architecture and Containers

### Container Diagram
```mermaid
graph TD
    User([User / Browser]) -->|Port 80/443| Traefik[Traefik Proxy]

    subgraph "Proxy Network"
        Traefik --> Fileserver[Fileserver Test - Nginx]
        Traefik --> Tomcat[Tomcat - Andromeda Test]
        Traefik --> AndromedaDev[Andromeda Dev - External/Host]
    end

    subgraph "Internal Network"
        Traefik --> Prometheus[Prometheus]
        Traefik --> Grafana[Grafana]
        
        Prometheus --> NodeExporter[Node Exporter]
        Prometheus --> Promtail[Promtail]
        
        Promtail --> Loki[Loki]
        Grafana --> Prometheus
        Grafana --> Loki

        Tomcat --> MariaDB[(MariaDB)]
        Tomcat --> Postgres[(PostgreSQL)]
        Tomcat --> Mongo[(MongoDB)]
    end
```

### Services Description
- **Traefik**: Edge router and reverse proxy. Handles TLS termination and routing to services.
- **Monitoring Stack**:
    - **Prometheus**: Metrics collection and storage.
    - **Grafana**: Visualization of metrics and logs.
    - **Node-exporter**: Collects host system metrics.
    - **Loki**: Log aggregation system.
    - **Promtail**: Ships logs from Docker containers and system to Loki.
- **Application Services**:
    - **Fileserver-test**: Nginx serving static resources.
    - **Tomcat-test-andromeda**: Java application server running the Andromeda test app.
- **Databases**:
    - **MariaDB**, **PostgreSQL**, **MongoDB**: Test databases for applications.

## Starting the Environment
To start all services:
```bash
docker compose up -d
```
The Traefik dashboard will be available at [https://traefik.test.milkyway](https://traefik.test.milkyway).
