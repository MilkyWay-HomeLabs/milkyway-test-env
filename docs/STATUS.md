# Status — 2026-07-14

Where the environment stands at the end of the migration day, and what is still open.

## Done

**One source of truth.** `infrastructure/docker/test` is the deployed environment *and*
the checkout of the public repo `MilkyWay-HomeLabs/milkyway-test-env`. Branch `main`,
pushed, default. The old copy at `repo/env/milkyway-test-env` is dead — do not edit it.

**Cutover executed.** All 22 containers run under `<app>-<role>-test`. Databases were
recreated against their existing volumes; row counts verified against the pre-migration
snapshot and unchanged.

**Segmentation enforced.** `auth-net` (172.23.0.0/24, `internal: true`) carries Andromeda
and Nebula only. Verified live: Nebula reaches the authorization server, Hacman does not,
fronts cannot reach any database, `/andromeda` returns 404.

**Secrets rotated.** Every database password, `APP_JWT_SECRET`, `SPRING_SECURITY_PASSWORD`,
`ENCRYPTION_KEY`, Grafana, the Traefik dashboard, and the restic key. Old values verified
rejected. Real values live only in the master file outside git.

**Public repo cleaned.** Eight branches carrying leaked `.example` values deleted; `main`
is the only branch and is clean.

## Bugs found and fixed on the way

Each of these was invisible while the system appeared to work:

1. **Mongo backups had been writing 0-byte archives since at least 2026-05-31.** The
   `backup` user declared in `mongo.env` did not exist in MongoDB, and the job still
   exited 0.
2. **The Postgres `backup` user had SELECT on nothing.** The init SQL ran every `GRANT`
   while connected to the `postgres` database — `GRANT CONNECT ON DATABASE x` does not
   switch you into `x`. `pg_dump test_hacman` had been failing for months while the job
   reported success.
3. **`run_backups.sh` pointed at the pre-rename container names**, and is baked into the
   image — editing it on disk does nothing without `docker compose -p test build backup-test`.
4. **compose mounted a `django.conf` that does not exist**, which on recreate would have
   left chess-front on nginx's stock config: 404 on every deep link.
5. **A 230 MB tarball reached the initial commit**, taking the repo to 238 MB. GitHub
   rejects files over 100 MB, so the push would have failed. History rewritten; 5.8 MB now.
6. **`env/backup/restic.env.exmaple`** — misspelled, so it dodged the `.gitignore` rule and
   every review, and published the backup repository's encryption key for months.

## Still open

**TLS certificate.** `traefik/certs/milkyway.key` was in the public history. Regenerate and
re-trust. Low urgency (self-signed, test only), but do it.

**Chess authenticates against Andromeda directly.** It is the one deviation from the
architecture, and the reason `chess-rest-test` still holds `auth-net` membership. Removing
that one block in `docker-compose.yml` is the whole fix — but only after Chess
authenticates through Nebula, or login breaks on the next recreate. See
`docs/ARCHITECTURE.md` § Current deviations.

**GitHub still serves the old commits.** Deleting the branches did not remove them:
`refs/pull/N/head` keeps every pull request's commits reachable by SHA. Everything they
expose is rotated and dead, so the risk is patterns, not credentials. To close it, either
ask GitHub Support to purge the PR refs, or delete and recreate the repository.

**`milkyway-home-lab` still has prod secrets in its history.** `prod/.env` and
`prod/env/db/*.env` were committed there before the ignore rule existed. They have been
untracked and are now gitignored by pattern, but the history retains them. That repository
is private, so this is not a public exposure — but the prod passwords should still be
rotated on their own schedule.

**No CI.** GitHub Actions is the chosen platform; no workflows exist yet. `docs/SECRETS.md`
§ CI lists which secrets a pipeline would need — the database passwords are not among them.

## The one rule to remember

A job that exits 0 is not proof it worked. Three of the six bugs above reported success
while doing nothing. Check what was actually written:

```bash
find backups -name '*.gz' -size 0     # must print nothing
```
