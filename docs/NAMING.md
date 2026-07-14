# Naming convention

## The rule

```
<app>-<role>-test
```

`role` is one of **`rest`**, **`front`**, **`game`** — plus **`auth`** for Andromeda,
which is neither. Infrastructure containers are `<component>-test`.

The compose **service key**, the **`container_name`** and the **DNS name** are all the
same string. There is exactly one name per container to remember, and it is the name you
see in `docker ps`.

> This matters more than it looks. Docker Compose registers the *service key* as the DNS
> name on the network — not `container_name`. When the two differ, `docker ps` shows one
> name and the config files reference another. That is exactly how this environment ended
> up with `milky-test-mariadb` in `docker ps` while every connection string said
> `mariadb-test`. Keeping them identical removes a whole category of confusion.

## Current containers

| Application | rest | front | game |
|---|---|---|---|
| andromeda | `andromeda-auth-test` | — | — |
| nebula | `nebula-rest-test` | `nebula-front-test` | — |
| chess | `chess-rest-test` | `chess-front-test` | `chess-game-test` |
| hacman | `hacman-rest-test` | `hacman-front-test` | `hacman-game-test` |
| robak | `robak-rest-test` *(pending)* | `robak-front-test` | `robak-game-test` |
| element | `element-rest-test` | `element-front-test` | `element-game-test` |
| racer | `racer-rest-test` | `racer-front-test` | `racer-game-test` |
| puzzel | `puzzel-rest-test` | `puzzel-front-test` | `puzzel-game-test` |

*(The last three are reserved names — see `docs/future/ADDING-AN-APP.md`.)*

Infrastructure: `traefik-test`, `prometheus-test`, `grafana-test`, `loki-test`,
`promtail-test`, `node-exporter-test`, `fileserver-test`, `backup-test`,
`mariadb-test`, `postgres-test`, `mongo-test`.

## What it replaced

| Old | New | Why it was a problem |
|---|---|---|
| `tomcat-test-andromeda` | `andromeda-auth-test` | Named after the servlet container, not the application. Says nothing about what it does. |
| `tomcat-test-nebula` | `nebula-rest-test` | Same. Also inconsistent with its own front-end, which used the opposite word order. |
| `nebula-front-app-test` | `nebula-front-test` | `-app-` carried no information. |
| `hacman-app-back-test` | `hacman-rest-test` | Service key was `hacman-app-back`, container was `hacman-app-back-test` — two names for one thing. `back` vs `rest` was a third word for the same role. |
| `chess-game-front-test` | `chess-game-test` | Both "game" and "front" in one name, for a container that is one or the other. |
| `milky-test-mariadb` | `mariadb-test` | `milky-` prefix appeared on the databases and nowhere else; word order reversed relative to every other container. |
| `traefik`, `grafana`, `loki`, … | `…-test` | Unsuffixed names collide with any other environment on the same host. |

## Rules for new containers

1. **Application first, role second, environment last.** `element-rest-test`, never
   `test-rest-element` or `element-app-rest`.
2. **Service key = container_name.** Do not set one without the other, and never make
   them differ.
3. **One word per role.** `rest`, not `back`/`backend`/`api`. `front`, not `front-app`.
   `game`, not `game-front`.
4. **Suffix the environment.** `-test` here, `-prod` in production. It is what stops two
   environments on one host from fighting over a name.
5. **The name is a contract.** It is the container's DNS name, so it appears in
   `traefik/config/dynamic.yml`, `prometheus/prometheus.yml`, the `*.properties` files
   and the hacman connection string. Renaming a container means grepping for the old name
   across all of them — see `docs/MIGRATION.md` for the checklist.

## Directories follow the containers

A container's build context and assets live in a directory with **the same name**, minus
the `-test` suffix:

```
nginx/chess-front/          ->  chess-front-test
  Dockerfile, nginx.conf         (source — committed)
  dist/                          (current bundle — gitignored)
  archive/                       (superseded bundles — gitignored)

nginx/nebula-front/  nginx/hacman-game/  nginx/robak-front/  nginx/robak-game/

django/chess-game/          ->  chess-game-test
  app/                           (the application, its own git checkout — gitignored)
  archive/                       (superseded builds — gitignored)
```

This replaced ten sibling directories — `chess-front-app` next to `chess-front-archive`,
and so on — where the pairing was implied by a suffix and no directory name matched any
container. Now there is one name: the container, its directory, its DNS name.

`django/chess-game` carries one extra level because `app/` is a git checkout of its own.
The archive sits *beside* it, not inside it, so it does not pollute that repository.

**Archives are gitignored, and must stay that way.** A 230 MB bundle tarball reached the
initial commit through a gap in the ignore rules. GitHub rejects any file over 100 MB, so
the push would have failed outright — and the repository had already grown to 238 MB. It
is now 5.8 MB.
