# jar/element-rest — deployment slot for element-rest-test

`docker-compose.yml` bind-mounts **`element-rest-api.jar`** from this directory to
`/app/element-rest-api.jar` inside `element-rest-test`. The jar is a build artifact and is
gitignored (`jar/*/*.jar`); this README exists so the directory is present in a fresh
clone. **If the jar is missing when the container starts, Docker creates a *directory* in
its place and the container restart-loops on `Error: Unable to access jarfile`** — so
build and copy it before `up`.

Why a jar and not a WAR in the shared Tomcat image: `element-rest-api` is a Spring Boot 4
fat jar with an embedded Tomcat, run by a plain `eclipse-temurin:25-jre`. Its context path
`/element/api` comes from its own `application.yml`, which is why the Traefik route does
not strip the prefix.

## Deploying a new build

```bash
./scripts/deploy-element.sh api
```

That builds in a Maven container (no local JDK), archives the running jar, swaps the new
one in, recreates the container and does not return until
`https://milkyway.test/element/api/v1/version` answers 200. `front` / `game` / no argument
deploy the bundles / all three.

By hand it is:

```bash
docker run --rm -v "$PWD":/app -w /app maven:3.9-eclipse-temurin-25 mvn -B -DskipTests package
cp target/element-rest-api-*.jar <this-dir>/.element-rest-api.jar.new
mv <this-dir>/.element-rest-api.jar.new <this-dir>/element-rest-api.jar
docker compose -p test up -d --no-deps --force-recreate element-rest-test
```

Three details, each learned the hard way:

- **Write-and-rename, never `cp` over the jar.** It is bind-mounted into a running JVM, so
  overwriting it in place mutates the file that process has open: the app keeps answering
  until it needs a class it had not loaded, then dies with `ClassNotFoundException` on
  Logback internals and stops responding entirely while the container still reports `Up`.
- **`--force-recreate`.** A bind-mounted file changing is invisible to compose; a plain
  `up -d` reports the container up to date and leaves the *old* build running.
- **`--no-deps`.** This directory's `env/db/postgres.env` is also read by `postgres-test`
  and `backup-test`, so without it compose offers to recreate the databases.

Keep the previous jar in `archive/` (gitignored) for a quick rollback.

Flyway runs on startup and owns the schema, so a deploy that adds migrations changes the
database the moment the container comes up. `spring.jpa.hibernate.ddl-auto` is `validate`:
Hibernate will refuse to start if the entities and the migrated schema disagree, which is
the intended tripwire.
