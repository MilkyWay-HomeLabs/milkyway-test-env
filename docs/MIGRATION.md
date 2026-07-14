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

## Phase 6 — the cutover (EXECUTED 2026-07-14)

**Done.** All 22 containers now run under the new names, the databases were recreated
against their existing volumes with row counts verified against the pre-migration
snapshot, and the segmentation was tested end to end (see "What the cutover found").

Two things made the cutover safe, and both are worth understanding if you ever repeat a
rename like this:

**1. Transitional network aliases.** Every renamed container temporarily carried an
`aliases:` entry for its old DNS name, so `dynamic.yml` (still saying
`http://tomcat-test-nebula:8080`) kept resolving through the rename and nothing 502'd.
They have since been removed, now that every config file uses the new names.

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
- **Restic and TLS** rotation, deliberately deferred — both have failure modes worse than
  the leak (unreadable snapshots; a re-trust dance on every client).
- **CI.** GitHub Actions, decided 2026-07-14. No workflows exist yet. The stray
  `Jenkinsfile` in `chess-game-front` is from an abandoned setup — ignore it, and do not
  build against it. See `docs/SECRETS.md` § CI for which secrets a pipeline would need
  (the database passwords are not among them).

## What the cutover found

Three things only showed up once the containers were actually recreated. Worth recording,
because none of them were visible in a running system.

**1. `chess-front-test` and `fileserver-test` mounted a `django.conf` that does not exist.**
The running containers had been created from an older compose and mounted
`nginx.conf → /etc/nginx/nginx.conf`; the compose file had drifted away from them. On
recreate, Docker would have created a *directory* named `django.conf` and left nginx on
its stock config — no SPA fallback, so every deep link would 404. Caught by a preflight
check that every bind-mount source exists before recreating anything. Fixed in `2ba6b7d`.

**2. Renaming a compose *service key* does not replace the container — it creates a second
one.** `mariadb-test` kept its key and was replaced cleanly. But `tomcat-test-nebula` →
`nebula-rest-test` is a *new service*, so compose started the new container and left the
old one running as an orphan. Both answered to `tomcat-test-nebula` (the new one via its
transitional alias), so Traefik would have load-balanced across old and new at random.
`--remove-orphans` is what cleans it up, and it is not optional during a rename.

**3. Taking Andromeda off `proxy` did NOT remove its public route.** `/andromeda` still
answered 401 afterwards. Traefik is also on `internal`, where Andromeda still lives for
its database connection — so the router kept resolving. Network membership alone does not
close a Traefik route; **the router has to be deleted too**. It now 404s.

The lesson in all three: a config that looks correct against a *running* system can still
be wrong, because the running system was built from something else. Verify against
`docker inspect`, not against the file you are reading.

## Verified after cutover

| Check | Result |
|---|---|
| `test_andromeda.users` | 18 — matches pre-migration snapshot |
| `test_hacman.level_scores` | 9604 — matches |
| `test_players.nationalities` | 249 — matches |
| `robak.region` | 1024 — matches |
| `test_puzzel.metadata` | 1 — matches |
| All app routes through Traefik | 200 |
| `/andromeda` | 404 — no public route |
| `nebula-rest-test` → Andromeda | reachable ✅ (required) |
| `hacman-rest-test` → Andromeda | no route ✅ (required) |
| `chess-front-test` → MariaDB | no route ✅ (required) |
| `chess-rest-test` → Andromeda | reachable ⚠️ — the known deviation, still intact |

Transitional aliases have been removed; `dynamic.yml`, `prometheus.yml` and the properties
files all use the new names.
