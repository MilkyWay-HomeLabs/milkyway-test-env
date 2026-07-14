# Migration — 2026-07-14

Merging the public `milkyway-test-env` repository into the deployed environment, so that
there is one directory and one source of truth.

## What was wrong

The environment existed twice. `repo/env/milkyway-test-env` was a public git repo holding
the configuration; `infrastructure/docker/test` was the copy that actually ran, tracked
nowhere. Every change had to be made in both, by hand, and they had already drifted.

Along the way, three other problems were in scope:

- Container names followed four different conventions at once.
- Nothing enforced which containers were allowed to talk to which.
- Real credentials — including a working Gmail app password — were committed to the
  **public** repo's history.

## What changed

**The deployed directory won.** `infrastructure/docker/test` is now the only copy, and it
is itself the checkout of the public repo. The old `repo/env/milkyway-test-env` working
copy is archived and gone.

| | Before | After |
|---|---|---|
| Source of truth | two, diverging | `infrastructure/docker/test` |
| Container names | `tomcat-test-nebula`, `nebula-front-app-test`, `milky-test-mariadb`, … | `<app>-<role>-test` throughout (`docs/NAMING.md`) |
| DNS vs `docker ps` | different strings | identical — service key = container_name |
| Andromeda | publicly routed at `/andromeda`, reachable by every backend | no public route; reachable only by Nebula, over `auth-net` |
| Networks | `proxy`, `internal` | `proxy`, `internal`, **`auth-net`** (`internal: true`) |
| IPs | ad-hoc | per-app /10 blocks, stable last octet (`docs/ARCHITECTURE.md`) |
| Secrets in git | committed, in a public repo | ignored by pattern; `.example` templates only |
| element/racer/puzzel | undocumented half-provisioned DBs | reserved IPs, naming, paste-ready compose (`docs/future/`) |

## Phase 0 — the backup (done first, before anything else)

`infrastructure/docker/backups/pre-merge-2026-07-14/` — 2.2 GB, `MANIFEST.md` with
SHA-256 for every artifact:

- **Logical dumps** — all MariaDB databases, `pg_dumpall`, `mongodump`.
- **Volume tarballs** — all 7 named volumes, taken from **read-only mounts of the live
  volumes**. No container was stopped.
- **Config snapshots** — both directory trees, plus `env/` and `.env` separately (`600`).
- **State** — `docker inspect` of every container, both networks, the live IP map, and
  per-table row counts to verify against after the cutover.

## Phase 6 — the cutover (NOT yet executed)

Everything above is on disk. **No running container has been touched.** Compose,
properties, `prometheus.yml` and the SQL init files are all read at *container start*, so
the changes are inert until something is recreated.

Two things make the cutover safe, and both are worth understanding before you run it:

**1. Transitional network aliases.** Every renamed container carries an `aliases:` entry
for its old DNS name. `traefik/config/dynamic.yml` still says
`http://tomcat-test-nebula:8080` — and that keeps resolving after the rename, because
`nebula-rest-test` also answers to `tomcat-test-nebula`. Nothing 502s mid-rename.

**2. `dynamic.yml` is hot-reloaded** (`watch: true` in `traefik.yml`). Editing it takes
effect *immediately*, on the running Traefik, with no recreate. Do not update the
hostnames in it until the containers have actually been renamed — the aliases exist
precisely so you do not have to.

### Steps

```bash
cd /home/wolf/MilkyWayHomeLab/infrastructure/docker/test

# 0. Confirm the project name. Volumes are prefixed `test_`; a different project name
#    means compose creates NEW EMPTY volumes and the databases look wiped.
docker compose -p test config --volumes     # mariadb-data, postgres-data, mongo-data, ...

# 1. Dry run. Anything compose wants to recreate that you did not expect is a red flag.
docker compose -p test up -d --no-recreate --dry-run

# 2. Create auth-net (additive, touches nothing).
docker network create --internal --subnet 172.23.0.0/24 auth-net

# 3. Recreate one container at a time, verifying between each.
#    Databases first — they are the ones with data, so do them while you are freshest.
#    A recreate does NOT touch the named volume; the data is in test_mariadb-data,
#    not in the container. Verify anyway.
docker compose -p test up -d --force-recreate mariadb-test
docker exec -e MYSQL_PWD=<root> mariadb-test mariadb -u root -e "SHOW DATABASES;"
#    -> compare row counts against backups/pre-merge-2026-07-14/state/rowcounts-mariadb.txt

docker compose -p test up -d --force-recreate postgres-test mongo-test
# ... verify likewise

# 4. Then the apps, in dependency order, checking each through Traefik before moving on.
docker compose -p test up -d --force-recreate andromeda-auth-test
docker compose -p test up -d --force-recreate nebula-rest-test nebula-front-test
curl -k https://milkyway.test/nebula/app/
docker compose -p test up -d --force-recreate hacman-rest-test hacman-front-test hacman-game-test
docker compose -p test up -d --force-recreate chess-rest-test chess-front-test chess-game-test
docker compose -p test up -d --force-recreate robak-front-test robak-game-test

# 5. Infrastructure last (traefik itself will drop connections briefly).
docker compose -p test up -d --force-recreate prometheus-test grafana-test loki-test \
                                              promtail-test node-exporter-test backup-test
docker compose -p test up -d --force-recreate traefik-test
```

### Then verify the segmentation actually holds

```bash
# Nebula CAN reach the authorization server:
docker exec nebula-rest-test bash -c 'curl -s -o /dev/null -w "%{http_code}" http://andromeda-auth-test:8080/'

# Hacman CANNOT — this must fail to resolve or connect:
docker exec hacman-rest-test sh -c 'curl -s --max-time 3 http://andromeda-auth-test:8080/' \
  && echo "SEGMENTATION BROKEN" || echo "OK: no route"

# And Andromeda is no longer publicly routed:
curl -k -o /dev/null -w '%{http_code}\n' https://milkyway.test/andromeda   # expect 404
```

Chess will still reach Andromeda — that is the known deviation, documented in
`docs/ARCHITECTURE.md`. It is not a failed check.

### Only after the stack is healthy

Now the old names are no longer needed:

1. Update `traefik/config/dynamic.yml` to the new hostnames (this is live — watch the logs).
2. Delete every `aliases:` block from `docker-compose.yml`.
3. Recreate once more, and re-run the checks.

### Rollback

The old tree is at `test.pre-merge.bak/` (if you moved it) and, regardless, in
`backups/pre-merge-2026-07-14/config/test-config-B.tgz`. Restore it and
`docker compose -p test up -d`.

**The named volumes were never destroyed at any point** — no step in this migration runs
`down -v` or removes a volume. If the data ever looks wrong, the first thing to check is
the *project name*, not the data: `docker compose` without `-p test` invents a new project
and a new, empty set of volumes.

## Still open

- **Rotate the leaked secrets.** Purging git history does not un-leak them. The Gmail app
  password should be revoked at Google *first*, independently of everything else here.
  See `docs/SECRETS.md` and the master file.
- **Chess → Nebula auth.** Until then, `chess-rest-test` keeps its `auth-net` membership.
- **Remove the transitional aliases** once `dynamic.yml`, the properties and
  `prometheus.yml` all use the new names.
- **Restic and TLS** rotation, deliberately deferred — both have failure modes worse than
  the leak (unreadable snapshots; a re-trust dance on every client).
- **CI.** GitHub Actions, decided 2026-07-14. No workflows exist yet. The stray
  `Jenkinsfile` in `chess-game-front` is from an abandoned setup — ignore it, and do not
  build against it. See `docs/SECRETS.md` § CI for which secrets a pipeline would need
  (the database passwords are not among them).
