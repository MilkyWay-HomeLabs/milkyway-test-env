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

From the `element-rest-api` checkout (no local JDK needed):

```bash
docker run --rm -v "$PWD":/app -w /app maven:3.9-eclipse-temurin-25 mvn -B -DskipTests package
cp target/element-rest-api-*.jar <this-dir>/element-rest-api.jar
docker compose -p test up -d --no-deps element-rest-test
```

`--no-deps` matters: this directory's `env/db/postgres.env` is also read by `postgres-test`
and `backup-test`, so without it compose offers to recreate the databases.

Keep the previous jar in `archive/` (gitignored) for a quick rollback.

Flyway runs on startup and owns the schema, so a deploy that adds migrations changes the
database the moment the container comes up. `spring.jpa.hibernate.ddl-auto` is `validate`:
Hibernate will refuse to start if the entities and the migrated schema disagree, which is
the intended tripwire.
