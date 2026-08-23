# Status — 2026-07-26

Where the environment stands, and what is still open.

## Done

**Element is deployed (2026-07-25).** Three new containers — `element-rest-test` (.150),
`element-front-test` (.151), `element-game-test` (.152) — serving
`https://milkyway.test/element/{api,app,game}`, plus the `/dev/element/...` routes that
proxy to a developer's local instances. It is the first application here that is **not** a
WAR in the shared Tomcat image: `element-rest-api` is a Spring Boot 4 fat jar on
`eclipse-temurin:25-jre`, deployed from `jar/element-rest/` (see the README there), and the
first to run on **PostgreSQL** — `test_element`, owned by `element`, 37 tables built by
Flyway on first start. Because the app carries its own context path `/element/api`, its
route is the one API route with **no** `strip` middleware. Verified: all six routes serve,
`/element/api/v1/me` returns 401 without a cookie, the panel's SPA deep links fall back to
`index.html`, and the e2e smoke tests of both front apps pass on both the dev and the
deployed route. The unused MariaDB `test_element` is a leftover from before Element chose
PostgreSQL.

**One source of truth.** `infrastructure/docker/test` is the deployed environment *and*
the checkout of the public repo `MilkyWay-HomeLabs/milkyway-test-env`. Branch `main`,
pushed, default. The old copy at `repo/env/milkyway-test-env` is dead — do not edit it.

**Cutover executed.** All 22 containers run under `<app>-<role>-test`. Databases were
recreated against their existing volumes; row counts verified against the pre-migration
snapshot and unchanged.

**Segmentation enforced — but see the correction in "Bugs found", item 7.** `auth-net`
(172.23.0.0/24, `internal: true`) carries Andromeda and Nebula only, fronts cannot reach
any database, and `/andromeda` returns 404 because Andromeda has no route from `proxy`.
The claim this section used to make — that Hacman "does not" reach the authorization
server — is false, and was measured wrong.

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
7. **"Hacman cannot reach the authorization server" was never true** (found 2026-07-25,
   while adding Element). Andromeda sits on `internal` as well as `auth-net` — it needs
   `internal` for MariaDB and for Prometheus to scrape it — and every REST API is on
   `internal` to reach its own database. So `andromeda-auth-test:8080` answers `HTTP/1.1
   401` from `hacman-rest-test` and from `element-rest-test`, neither of which is on
   `auth-net`. What `auth-net` actually buys is that Andromeda has **no route from
   `proxy`**, so it is unreachable from outside; "only Nebula may reach it" is a
   convention the code upholds, not one the network enforces. The check in
   `docs/future/ADDING-AN-APP.md` asserted the wrong thing and has been replaced with a
   network-membership check, which is the property that can actually be verified. Closing
   the gap for real means taking Andromeda off `internal`, which costs it its database
   and its scrape target — a decision, not a fix.
8. **The Postgres `backup` user needs SEQUENCES, not just TABLES** (found 2026-07-25).
   `test_element`'s first dump produced **0 bytes** with `SELECT` already granted on all
   37 tables: `pg_dump` also reads every sequence's `last_value`, and it fails there
   *before* writing anything, so the result is an empty file rather than a partial one —
   the same silent shape as bug 2. Both grants are now in
   `sql/postgres/000_create_databases_and_users.sql`.
9. **`APP_JWT_SECRET` is Base64, and an app that reads it as raw bytes rejects every real
   token** (found 2026-07-26, while running Element's cross-service e2e suite). Andromeda
   signs with `Keys.hmacShaKeyFor(Decoders.BASE64.decode(APP_JWT_SECRET))`, so the
   configured value is the *encoding* of the key, not the key. `element-rest-api` took the
   string's UTF-8 bytes instead and derived a key that verified nothing the platform
   issues: every authenticated request answered `401 AUTH_REQUIRED` in the deployed
   environment, while its own tests passed because they signed the same wrong way the
   parser verified. Two more facts a new app needs: the token is **HS384**, not HS256, so
   do not pin the algorithm on the parser; and its subject is the **user id alone** — the
   `"<userId>,<email>"` composite other platform APIs document is not what Andromeda
   sends, so an app that splits on the comma must tolerate its absence. An app that
   validates the cookie locally is not integrated until a token Andromeda actually issued
   has been through it.

## Still open

**Andromeda writes a malformed `Expires` on its cookies** (found 2026-07-26).
`Set-Cookie: ...; Expires=Sun 26 Jul 2026 095759 GMT` — no comma after the weekday and no
colons in the time, so it parses as neither RFC 1123 nor any of the fallbacks. Browsers
prefer `Max-Age`, which is why sign-in works everywhere and nobody noticed; a cookie jar
that parses what it can (Playwright's, for one) lands on midnight of that day and drops
the access cookie as already expired. Not this environment's file to fix — recorded here
because it makes any non-browser client of the platform look broken for no visible reason.


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
