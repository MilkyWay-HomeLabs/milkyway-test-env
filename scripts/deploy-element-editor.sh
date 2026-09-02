#!/usr/bin/env bash
#
# deploy-element-editor.sh — build and deploy element-editor's two services
# into this environment, then prove the routes answer.
#
#   ./scripts/deploy-element-editor.sh            # both
#   ./scripts/deploy-element-editor.sh api        # element-editor-rest-test only
#   ./scripts/deploy-element-editor.sh front      # element-editor-front-test only
#
# Source checkout is looked up next to this repository and can be overridden:
#
#   ELEMENT_EDITOR_SRC=/path/to/element-editor ./scripts/deploy-element-editor.sh
#
# Modeled on deploy-element.sh, adapted for a single-repo Node/TS backend +
# Vite frontend instead of a Maven jar: `npm run build` (tsc) needs no local
# JDK-equivalent container, and the deployable backend artifact is dist/ +
# node_modules + package.json rather than one fat jar — see deploy_api below
# for why that still gets the same archive-then-atomic-swap treatment the jar
# does.
#
# Test environment only — this tool has no production deployment, ever.
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab="$(cd "$here/../../.." && pwd)"          # .../MilkyWayHomeLab

SRC="${ELEMENT_EDITOR_SRC:-$lab/repo/dev/element-editor}"
BASE_URL="${ELEMENT_EDITOR_BASE_URL:-https://milkyway.test}"
stamp="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m    %s\033[0m\n' "$*"; }
die()  { printf '\033[31mdeploy-element-editor: %s\033[0m\n' "$*" >&2; exit 1; }

# Poll a route until it answers the expected status. Nothing here is worth
# trusting on an exit code alone — the point of the script is the check.
verify() {
  local url="$1" want="${2:-200}" tries="${3:-30}" code=
  for _ in $(seq "$tries"); do
    code="$(curl -sk --max-time 5 -o /dev/null -w '%{http_code}' "$url" || true)"
    [ "$code" = "$want" ] && { printf '    %s -> %s\n' "$url" "$code"; return 0; }
    sleep 2
  done
  die "$url answered $code, expected $want"
}

deploy_api() {
  local backend="$SRC/backend"
  [ -d "$backend" ] || die "no element-editor checkout at $backend (set ELEMENT_EDITOR_SRC)"
  say "element-editor backend: npm ci && npm run build"
  (cd "$backend" && npm ci && npm run build)
  [ -d "$backend/dist" ] || die "the build produced no dist/ in $backend"

  local slot="$here/node/element-editor-rest"
  mkdir -p "$slot/archive"
  if [ -d "$slot/current" ]; then
    mv "$slot/current" "$slot/archive/current-$stamp"
    printf '    previous build kept at node/element-editor-rest/archive/current-%s\n' "$stamp"
  fi
  # Build the new slot beside the live one and rename into place, same reason
  # as the jar: a bind mount changing files a running process already has open
  # should not happen mid-write. Node does not lock a required file the way a
  # JVM does, but there is no upside to finding out the hard way.
  local build_dir="$slot/.new"
  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  # /app is a read-only bind mount, and Docker cannot create a missing
  # mountpoint directory inside a read-only mount at container start — so
  # /app/output (the separate, writable bind mount for OUTPUT_DIR) must
  # already exist in the slot before the container is created.
  mkdir -p "$build_dir/output"
  cp -r "$backend/dist" "$build_dir/dist"
  cp -r "$backend/node_modules" "$build_dir/node_modules"
  cp "$backend/package.json" "$build_dir/package.json"
  mv "$build_dir" "$slot/current"

  # --force-recreate is not optional: the build is a bind mount, so its content
  # changing is invisible to compose and a plain `up -d` reports the container
  # up to date and leaves the old build running.
  say "element-editor backend: recreating element-editor-rest-test"
  (cd "$here" && docker compose -p test up -d --no-deps --force-recreate element-editor-rest-test)

  verify "$BASE_URL/element/editor/api/health"
}

deploy_front() {
  local front="$SRC/frontend" slot="$here/nginx/element-editor-front/dist"
  [ -d "$front" ] || die "no element-editor checkout at $front (set ELEMENT_EDITOR_SRC)"
  say "element-editor frontend: npm run build"
  (cd "$front" && npm run build)
  [ -f "$front/dist/index.html" ] || die "$front/dist/index.html missing after the build"

  # Same class of bug M8 found in element-front-app: Vite reads .env.local in
  # every mode, so a machine set up for local dev work can bake a dev API URL
  # into a release bundle. .env.production outranks it — this is the assertion
  # that it did.
  if grep -rql 'localhost' "$front/dist"; then
    die "element-editor frontend bundle references localhost — built with a dev .env; refusing to deploy"
  fi

  mkdir -p "$here/nginx/element-editor-front/archive"
  if [ -d "$slot" ] && [ -n "$(ls -A "$slot" 2>/dev/null)" ]; then
    cp -r "$slot" "$here/nginx/element-editor-front/archive/dist-$stamp"
    printf '    previous bundle kept at nginx/element-editor-front/archive/dist-%s\n' "$stamp"
  fi
  rm -rf "${slot:?}"/*
  cp -r "$front/dist/." "$slot/"

  # dist is a read-only bind mount, so nginx serves the new files immediately —
  # no recreate needed for a redeploy. `up -d` (no --force-recreate) is the
  # first-deploy path: harmless no-op if the container is already running,
  # creates and starts it if this is the very first deploy — found by hand
  # the first time this script ran, when there was nothing yet to serve the
  # freshly-swapped files and the route answered 502.
  (cd "$here" && docker compose -p test up -d --no-deps element-editor-front-test)
  verify "$BASE_URL/element/editor/app/"
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(all)
for t in "${targets[@]}"; do
  case "$t" in
    all)   deploy_api; deploy_front ;;
    api)   deploy_api ;;
    front) deploy_front ;;
    *)     die "unknown target '$t' (expected: all, api, front)" ;;
  esac
done

say "done"
