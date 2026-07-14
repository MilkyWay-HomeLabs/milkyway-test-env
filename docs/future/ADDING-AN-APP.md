# Adding an application (element, racer, puzzel)

Each new application gets three containers — **rest**, **front**, **game** — one IP block,
one database, one set of Traefik routes and one `env/` directory. This is the checklist.

`docs/future/element-racer-puzzel.yml` holds ready-to-paste compose blocks for all three.

## What already exists

Some of the groundwork is done, which is easy to miss:

| App | Database | User | Status |
|---|---|---|---|
| **element** | MariaDB `test_element` | `element` | DB and user exist (`sql/mariadb/000_create_databases_and_users.sql`); password is `CHANGE_ME` and must be set |
| **racer** | MariaDB `test_racer` | `racer` | same |
| **puzzel** | MongoDB `test_puzzel` | `puzzel` | DB, user and a `metadata` collection exist (`sql/mongo/000_init_puzzel.js`) |

All three are also already listed in `ALLOWED_APPS_HEADERS` in
`env/tomcat/andromeda-authorization.properties` (`element_rest_api`, `racer_rest_api`).
**Remove them.** Under the current architecture a REST API does not authenticate against
Andromeda — it goes through Nebula. Leaving the header in place grants an access path the
app is not supposed to have. Add `puzzel` there only if you find you need it, which you
should not.

## Reserved addresses

| App | Block | rest | front | game |
|---|---|---|---|---|
| element | `.150` | `.150` | `.151` | `.152` |
| racer | `.160` | `.160` | `.161` | `.162` |
| puzzel | `.170` | `.170` | `.171` | `.172` |

Same last octet on every network the container joins.

## Checklist

### 1. Networks — get this right first

```yaml
<app>-rest-test:
  networks:
    proxy:     { ipv4_address: 172.21.0.<base> }      # Traefik routes to it
    internal:  { ipv4_address: 172.22.0.<base> }      # reaches its database
    # NO auth-net. The REST API authenticates through Nebula, never against
    # Andromeda directly. See docs/ARCHITECTURE.md.

<app>-front-test:
  networks:
    proxy:     { ipv4_address: 172.21.0.<base+1> }    # proxy ONLY

<app>-game-test:
  networks:
    proxy:     { ipv4_address: 172.21.0.<base+2> }    # proxy ONLY
```

A front or game container on `internal` is a bug — it has no business reaching a database.

### 2. Database

**MariaDB** (element, racer) — the database and user already exist. Set a real password:

```sql
ALTER USER 'element'@'%' IDENTIFIED BY '<from the secrets master file>';
```

and add the app's schema as `sql/mariadb/00N_<app>_model_and_data.sql`. Remember the SQL in
this repo is public: keep `CHANGE_ME` placeholders in the committed file.

**MongoDB** (puzzel) — already provisioned by `sql/mongo/000_init_puzzel.js`.

> Init scripts under `/docker-entrypoint-initdb.d` run **only on an empty data volume**.
> The volumes here are not empty. Adding a schema file does nothing to the running
> database — apply it by hand with `docker exec`, and keep the file for rebuilds.

### 3. Secrets

Create `env/tomcat/<app>-rest.properties` (copy an existing one) and
`env/nginx/<app>-front/.env`. For every file, commit a `.example` with `CHANGE_ME`
values — the real file is ignored by `.gitignore`'s `*.env` / `*.properties` patterns.

Record the new passwords in the secrets master file (path in `docs/SECRETS.md`).

### 4. Traefik routes

In `traefik/config/dynamic.yml`, add three routers and three services following the
established path scheme:

| Path | Goes to |
|---|---|
| `/<app>/api` | `<app>-rest-test:8080` — with a `strip-<app>` middleware |
| `/<app>/app/` | `<app>-front-test:80` — **no strip** if the bundle is built with that base path |
| `/<app>/game/` | `<app>-game-test:80` |

Whether to strip the prefix depends on how the front-end bundle was built. If it was built
with base `/<app>/app/` and its nginx serves that path, stripping hands nginx a bare `/`
and earns a 404. Chess and Robak differ here — read their comments before copying.

`dynamic.yml` is **hot-reloaded** (`watch: true`). A syntax error or a hostname that does
not resolve takes effect immediately. Add the compose service and start it *before* adding
its route.

### 5. Monitoring

Add a scrape job in `prometheus/prometheus.yml`. The target must be on `internal` —
Prometheus lives there and cannot see `proxy`-only containers, which is why the `front`
and `game` containers are not scraped.

### 6. Verify

```bash
docker compose -p test up -d <app>-rest-test <app>-front-test <app>-game-test
docker compose -p test logs -f <app>-rest-test

# The route works:
curl -k https://milkyway.test/<app>/app/

# And the segmentation holds — this MUST fail:
docker exec <app>-rest-test wget -qO- --timeout=3 http://andromeda-auth-test:8080/ \
  && echo "SEGMENTATION BROKEN: remove auth-net from this container" \
  || echo "OK: no route to the authorization server"
```
