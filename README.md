# MilkyWay Home Lab — Test Environment

Docker Compose environment running the MilkyWay applications behind Traefik with TLS,
backed by MariaDB, PostgreSQL and MongoDB, with Prometheus / Grafana / Loki for
observability.

**Version 2.0.0** · Apache-2.0 · Szymon Derleta

> **2.0.0 merged this repository with the deployed environment.** They used to be two
> copies that had to be edited in parallel, and they had drifted. This directory is now
> the only one — it is both the running environment and the git checkout.
> See [docs/MIGRATION.md](docs/MIGRATION.md).

## Applications

| App | REST | Front | Game | Database |
|---|---|---|---|---|
| **andromeda** | `andromeda-auth-test` — authorization server | — | — | MariaDB `test_andromeda` |
| **nebula** | `nebula-rest-test` | `nebula-front-test` | — | MariaDB `test_nebula` |
| **chess** | `chess-rest-test` | `chess-front-test` | `chess-game-test` | MariaDB `test_chess` |
| **hacman** | `hacman-rest-test` | `hacman-front-test` | `hacman-game-test` | PostgreSQL `test_hacman` |
| **robak** | *pending WAR* | `robak-front-test` | `robak-game-test` | MariaDB `test_robak` |
| **element** / **racer** / **puzzel** | reserved | reserved | reserved | see [docs/future/](docs/future/ADDING-AN-APP.md) |

Nebula is the SSO gateway. Andromeda is the authorization server, and **only Nebula may
talk to it** — a rule enforced by network membership, not by convention. Read
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before adding anything.

## Quick start

```bash
# 1. Host entry
echo '127.0.0.1 milkyway.test' | sudo tee -a /etc/hosts

# 2. TLS certificate (self-signed) — see traefik/certs/README.md.
#    Trust the generated cert, or every route will throw a browser warning.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout traefik/certs/milkyway.key -out traefik/certs/milkyway.crt \
  -subj "/C=PL/ST=Test/L=Test/O=MilkyWay/CN=milkyway.test" \
  -addext "subjectAltName=DNS:milkyway.test,DNS:*.milkyway.test"

# 3. Configuration. Every real value is CHANGE_ME until you fill it in.
for f in $(find . -name '*.example'); do cp -n "$f" "${f%.example}"; done
grep -rn CHANGE_ME --include='*.env' --include='*.properties' .

# 4. Start.
docker compose -p test up -d
```

Then open <https://milkyway.test/nebula/app/>.

| | |
|---|---|
| Traefik dashboard | <https://milkyway.test/dashboard/> |
| Grafana | <https://milkyway.test/grafana/> |
| Prometheus | <https://milkyway.test/prometheus/> |

## Three things that will bite you

**Never `docker compose down -v`.** The `-v` destroys the named volumes, and all three
databases live in them. There is no undo. Plain `down` is fine.

**Always pass `-p test`.** Without it, Compose derives the project name from the current
directory. A different project name means a *different set of volumes* — the databases
come up empty and it looks like the data is gone. It is not; you are looking at the wrong
volumes. Everything here assumes the project is called `test`.

**`traefik/config/dynamic.yml` is hot-reloaded** (`watch: true`). Saving it applies to the
running Traefik immediately — a typo or an unresolvable hostname breaks routing on the
spot. There is no apply step to catch the mistake first.

## Layout

```
docker-compose.yml       22 services, three networks
env/                     configuration and secrets — gitignored; *.example is committed
sql/                     schema + seed — applied ONLY to an empty database volume
traefik/                 traefik.yml (static) + config/dynamic.yml (hot-reloaded)
nginx/ kestrel/ django/  per-app build contexts and built bundles
tomcat/                  WARs and setenv scripts
backup/ backups/         the backup image, and its output (gitignored — holds real data)
prometheus/ loki/ promtail/
docs/
```

## Backups

`backup-test` dumps all three databases on a cron schedule into `./backups` (rotated,
optionally pushed to a restic repo). Run one by hand:

```bash
docker compose -p test exec backup-test /usr/local/bin/run_backups.sh
```

See [docs/BACKUP_GUIDE.md](docs/BACKUP_GUIDE.md) for restore.

## Documentation

| | |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | networks, IP plan, **who may talk to whom** |
| [NAMING.md](docs/NAMING.md) | the `<app>-<role>-test` convention |
| [SECRETS.md](docs/SECRETS.md) | where secrets live, how to rotate, the traps |
| [MIGRATION.md](docs/MIGRATION.md) | the 2026-07 merge and the cutover runbook |
| [BACKUP_GUIDE.md](docs/BACKUP_GUIDE.md) | backup and restore |
| [future/ADDING-AN-APP.md](docs/future/ADDING-AN-APP.md) | checklist for element / racer / puzzel |
| [CHANGELOG.md](docs/CHANGELOG.md) | history |
