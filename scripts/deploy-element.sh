#!/usr/bin/env bash
#
# deploy-element.sh — build and deploy the three Element services into this
# environment, then prove the routes answer.
#
#   ./scripts/deploy-element.sh            # all three
#   ./scripts/deploy-element.sh api        # element-rest-test only
#   ./scripts/deploy-element.sh front game # any subset
#
# Source checkouts are looked up next to this repository and can be overridden:
#
#   ELEMENT_REST_SRC=/path/to/element-rest-api ./scripts/deploy-element.sh api
#   ELEMENT_FRONT_SRC=...  ELEMENT_GAME_SRC=...
#
# Why this exists: deploying Element was four hand-run commands per service,
# written down in jar/element-rest/README.md and easy to half-remember. The
# e2e suite (M9) has to run against a freshly deployed stack, and a suite that
# depends on a hand deploy rots.
#
# What it refuses to do:
#   - deploy a front bundle containing "/dev/element", which means the build
#     inherited a developer's .env.local and would ship dev-route asset paths;
#   - leave a service unverified: each deploy ends with an HTTP check.
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab="$(cd "$here/../../.." && pwd)"          # .../MilkyWayHomeLab

REST_SRC="${ELEMENT_REST_SRC:-$lab/repo/back/element-rest-api}"
FRONT_SRC="${ELEMENT_FRONT_SRC:-$lab/repo/front/element-front-app}"
GAME_SRC="${ELEMENT_GAME_SRC:-$lab/repo/game/element-game-app}"

BASE_URL="${ELEMENT_BASE_URL:-https://milkyway.test}"
MAVEN_IMAGE="${MAVEN_IMAGE:-maven:3.9-eclipse-temurin-25}"
stamp="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m    %s\033[0m\n' "$*"; }
die()  { printf '\033[31mdeploy-element: %s\033[0m\n' "$*" >&2; exit 1; }

# Poll a route until it answers the expected status. Nothing here is worth
# trusting on an exit code alone — the point of the script is the check.
verify() {
  local url="$1" want="${2:-200}" tries="${3:-30}" code=
  for _ in $(seq "$tries"); do
    # --max-time matters: a container whose JVM is wedged accepts the connection
    # and never answers, and an unbounded curl turns a failed deploy into a hang.
    code="$(curl -sk --max-time 5 -o /dev/null -w '%{http_code}' "$url" || true)"
    [ "$code" = "$want" ] && { printf '    %s -> %s\n' "$url" "$code"; return 0; }
    sleep 2
  done
  die "$url answered $code, expected $want"
}

deploy_api() {
  [ -d "$REST_SRC" ] || die "no element-rest-api checkout at $REST_SRC (set ELEMENT_REST_SRC)"
  say "element-rest-api: building in $MAVEN_IMAGE (no local JDK needed)"
  docker run --rm \
    -v "$REST_SRC":/app -v "${HOME}/.m2":/root/.m2 -w /app \
    "$MAVEN_IMAGE" mvn -B -DskipTests package

  local built
  built="$(ls -t "$REST_SRC"/target/element-rest-api-*.jar 2>/dev/null | head -1)"
  [ -n "$built" ] || die "the build produced no jar in $REST_SRC/target"

  local slot="$here/jar/element-rest"
  mkdir -p "$slot/archive"
  if [ -f "$slot/element-rest-api.jar" ]; then
    cp "$slot/element-rest-api.jar" "$slot/archive/element-rest-api-$stamp.jar"
    printf '    previous jar kept at archive/element-rest-api-%s.jar\n' "$stamp"
  fi
  # Write beside the slot and rename, never `cp` over it. The jar is bind-mounted
  # into a running JVM: overwriting it in place changes the file the JVM has open
  # and the app dies mid-request with ClassNotFoundException on classes it had
  # not loaded yet. A rename gives the new build a new inode and leaves the
  # running process on the old one until it is restarted below.
  cp "$built" "$slot/.element-rest-api.jar.new"
  mv -f "$slot/.element-rest-api.jar.new" "$slot/element-rest-api.jar"

  # --force-recreate is not optional either: the jar is a bind mount, so its
  # content changing is invisible to compose and a plain `up -d` reports the
  # container up to date and leaves the old build running.
  # --no-deps is not optional: env/db/postgres.env is read by postgres-test and
  # backup-test too, so without it compose offers to recreate the databases.
  say "element-rest-api: recreating element-rest-test"
  (cd "$here" && docker compose -p test up -d --no-deps --force-recreate element-rest-test)

  # Flyway runs at startup and ddl-auto is validate, so a bad migration shows
  # up as a container that never serves — which is what the poll below catches.
  verify "$BASE_URL/element/api/v1/version"
}

# Build a Vite bundle in production mode and swap it into the nginx slot.
deploy_bundle() {
  local name="$1" src="$2" slot="$here/nginx/$3/dist" route="$4"
  [ -d "$src" ] || die "no $name checkout at $src"
  say "$name: npm run build"
  (cd "$src" && npm run build)

  [ -f "$src/dist/index.html" ] || die "$src/dist/index.html missing after the build"

  # The M8 lesson: Vite reads .env.local in every mode, so a machine set up for
  # dev-route work can bake /dev/element/... into a release bundle. .env.production
  # outranks it, and this is the assertion that it did.
  if grep -rql '/dev/element' "$src/dist"; then
    die "$name bundle contains /dev/element — built with a dev .env; refusing to deploy"
  fi

  mkdir -p "$here/nginx/$3/archive"
  if [ -d "$slot" ] && [ -n "$(ls -A "$slot" 2>/dev/null)" ]; then
    cp -r "$slot" "$here/nginx/$3/archive/dist-$stamp"
    printf '    previous bundle kept at nginx/%s/archive/dist-%s\n' "$3" "$stamp"
  fi
  rm -rf "${slot:?}"/*
  cp -r "$src/dist/." "$slot/"

  # dist is a read-only bind mount, so nginx serves the new files immediately —
  # no container restart, which is why none of these are touched.
  verify "$BASE_URL$route"
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(all)
for t in "${targets[@]}"; do
  case "$t" in
    all)   deploy_api
           deploy_bundle element-front-app "$FRONT_SRC" element-front /element/app/
           deploy_bundle element-game-app  "$GAME_SRC"  element-game  /element/game/ ;;
    api)   deploy_api ;;
    front) deploy_bundle element-front-app "$FRONT_SRC" element-front /element/app/ ;;
    game)  deploy_bundle element-game-app  "$GAME_SRC"  element-game  /element/game/ ;;
    *)     die "unknown target '$t' (expected: all, api, front, game)" ;;
  esac
done

say "done"
warn "The /dev/element/... routes still proxy to a developer's local servers and are"
warn "unaffected by this script."
