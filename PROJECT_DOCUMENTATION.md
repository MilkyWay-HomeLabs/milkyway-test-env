# MilkyWay Test Env Project Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Container Networks](#container-networks)
3. [Container Specification](#container-specification)
4. [Endpoints and Accessibility](#endpoints-and-accessibility)
5. [Volumes and Data](#volumes-and-data)

---

## System Overview
The `milkyway-test-env` project is a container-based test environment (Docker) used to host the Andromeda application, a file server, and a full monitoring stack (Prometheus, Grafana, Loki). The entire setup is secured and managed by the Traefik reverse proxy.

---

## Container Networks
Two main networks are defined in the system:
- **proxy (External/Bridge):** Used for communication between Traefik and containers exposing public/external services.
- **internal (Internal/Bridge):** Used for secure communication between applications, databases, and the monitoring system.

---

## Container Specification

### 1. Traffic Management (Proxy)
| Container | Image | Networks | Ports (Host) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **traefik** | `traefik:v3.2` | `proxy`, `internal` | `80`, `443` | Reverse proxy, TLS handling, dashboard. |

### 2. Applications and Servers
| Container | Image | Networks | Ports (Host) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **tomcat-test-andromeda** | `tomcat:10.1-jdk21` | `proxy`, `internal` | - | Andromeda application server ([Andromeda Authorization Server](https://github.com/MilkyWay-HomeLabs/andromeda-authorization-server-public)). |
| **fileserver-test** | `nginx:alpine` | `proxy` | - | Static file server for test resources. |

### 3. Monitoring and Logs
| Container | Image | Networks | Ports (Host) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **prometheus** | `prom/prometheus:v3.9.1` | `internal` | `9090` | Metrics collection. |
| **grafana** | `grafana/grafana:11.4.0` | `internal` | `3000` | Data visualization and dashboards. |
| **loki** | `grafana/loki:3.0.0` | `internal` | `3100` | Log aggregation. |
| **promtail** | `grafana/promtail:3.0.0` | `internal` | - | Agent for shipping logs to Loki. |
| **node-exporter** | `prom/node-exporter:v1.8.2` | `internal` | `9100` | Host system metrics. |

### 4. Databases
| Container | Image | Networks | Ports (Host) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **mariadb-test** | `mariadb:11` | `internal` | `3306` | MariaDB database. |
| **postgres-test** | `postgres:16` | `internal` | `5432` | PostgreSQL database. |
| **mongo-test** | `mongo:8` | `internal` | `27017` | MongoDB database. |

---

## Endpoints and Accessibility

### External Endpoints (via Traefik)
Accessible via domain addresses (requires entries in `/etc/hosts` or DNS). All HTTP endpoints are automatically redirected to **HTTPS (443)**.

| Service | URL | Type | Authentication |
| :--- | :--- | :--- | :--- |
| **Traefik Dashboard** | `https://traefik.test.milkyway` | External | Basic Auth |
| **Andromeda API** | `https://andromeda.test.milkyway/api` | External | App-dependent |
| **Grafana** | `https://grafana.test.milkyway` | External | Grafana Login |
| **Prometheus** | `https://prometheus.test.milkyway` | External | None (Public within test network) |
| **File Server** | `https://resources.test.milkyway` | External | None (Public) |

### Internal Endpoints (Docker Network)
Accessible only to other containers within the same Docker network.

| Service | Internal Address | Network |
| :--- | :--- | :--- |
| **MariaDB** | `mariadb-test:3306` | `internal` |
| **PostgreSQL** | `postgres-test:5432` | `internal` |
| **MongoDB** | `mongo-test:27017` | `internal` |
| **Loki** | `loki:3100` | `internal` |
| **Tomcat (Andromeda)** | `tomcat-test-andromeda:8080` | `internal`/`proxy` |

---

## Volumes and Data
The system uses Docker volumes to ensure data persistence:
- `mariadb-data`: MariaDB database data.
- `postgres-data`: PostgreSQL database data.
- `mongo-data`: MongoDB database data.
- `prometheus-data`: Prometheus time-series data.
- `grafana-data`: Grafana configuration and databases.
- `loki-data`: Stored logs.

Database initialization scripts are located in the `./sql` directory and are mounted to the respective containers in Read-Only mode.
