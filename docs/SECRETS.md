# Secrets

## Where they live

**Real values are never in this repository.** They exist in two places:

1. **On the host**, in the files this environment actually reads — every `*.env` and
   `env/**/*.properties`. These are ignored by `.gitignore`.
2. **In the secrets master file**, outside every git tree:
   `/home/wolf/MilkyWayHomeLab/_0utside/secrets/test-env-secrets-master.md` (mode `600`).
   It records, per secret: the old value, the new value, every file that consumes it,
   whether rotating it also needs a database `ALTER USER`, and whether it would ever be a
   CI secret.

The repository contains only `*.example` templates with `CHANGE_ME` placeholders.

## Setting up from a clean clone

```bash
for f in $(find . -name '*.example'); do cp -n "$f" "${f%.example}"; done
grep -rn CHANGE_ME --include='*.env' --include='*.properties' .   # fill each one in
```

## How .gitignore protects them

The rules are **deny-by-pattern**, not a list of filenames:

```
*.env
!*.env.example
env/**/*.properties
!env/**/*.properties.example
```

A new secret file is ignored **by default**. You have to opt in to committing one.

The previous version enumerated each file by name, which is how `env/nginx/chess/.env`
ended up neither ignored nor committed, and how real credentials reached a public repo.
Do not go back to enumeration.

**Before every push:**

```bash
git ls-files | grep -E '\.(env|properties)$' | grep -v '\.example$'   # must print nothing
git ls-files -z | xargs -0 grep -lE '(PASSWORD|SECRET|KEY)\s*=\s*[^C\s]' | grep -v example
```

## Rotating

Read the master file first — it says which type each secret is. The distinction that
matters:

- **`runtime-only`** — edit the file, recreate the container that reads it. Done.
- **`db-alter`** — the password also lives *inside the database*. Editing the env file
  alone changes nothing; the app just stops being able to log in. You must run
  `ALTER USER` / `SET PASSWORD` / `db.changeUserPassword()` against the running database
  **and** update the file, together.

Three traps worth naming:

**`MONGO_INITDB_ROOT_PASSWORD` does nothing on an existing volume.** Those variables are
read only when the data directory is empty. The Mongo volume is not empty. Rotate with
`db.changeUserPassword()`.

**`RESTIC_PASSWORD` is an encryption key, not a login.** Changing it in `restic.env` does
not re-key the repository — it makes every existing snapshot unreadable. Use
`restic key add` → verify → `restic key remove`.

**`HACMAN_PASSWORD` lives in two files.** It is in `env/db/postgres.env` and *embedded in
the connection string* in `env/kestrel/hacman/back/.env`. Change one without the other and
Hacman loses its database.

## Front-end "secrets" are not secret

`REACT_APP_PASSWORD` (chess) and `VITE_PASSWORD` (robak, nebula) are compiled into the
browser bundle at build time. Anyone who loads the page can read them — `.gitignore` does
not protect them, and never could. They are in the master file for completeness and
rotation, but the real fix is a server-side auth flow. See `docs/ARCHITECTURE.md`
§ Current deviations.

## The 2026-07 leak

The public repo `milkyway-test-env` carried working credentials in its git history,
including a **Gmail app password**, the shared `APP_JWT_SECRET`, and every database
password. `milkyway-home-lab` tracked `.env` and `env/db/*.env` from before its ignore rule
existed.

History has been purged and the values rotated. Purging history does **not** un-leak a
secret — anyone who cloned, forked, or scraped the repo still has the old values. The only
thing that helps is rotation, which is why every value in the master file has an `old` and
a `new` column.

## CI — GitHub Actions

**GitHub Actions is the CI platform.** Any `Jenkinsfile` still lying around in an
application repo (there is one in `chess-game-front`) is dead weight from an earlier setup
— do not treat it as the pipeline, and do not add secrets to a Jenkins credential store.

There are no workflows yet, so **nothing here is currently a live Actions secret**. The
master file's `ci` column marks which ones *would* be needed once a pipeline exists:

- **`ci-candidate`** — needed to *build* an app: `APP_JWT_SECRET`,
  `SPRING_SECURITY_PASSWORD`, `AUTH_MAIL_PASSWORD`, `DJANGO_SECRET_KEY`, and the
  front-end `VITE_*` / `REACT_APP_*` values that get baked into bundles.
- **`not-needed`** — every database password. CI builds artifacts; it does not connect to
  the test databases. If an integration-test job ever needs one, give it a throwaway
  database with its own password. Never these.

Set them per application repository:

```bash
gh secret set APP_JWT_SECRET --repo MilkyWay-HomeLabs/<app-repo>
```

The environment's own runtime secrets (everything under `env/`) are delivered by files on
this host, not by CI. A pipeline never needs them.
