# GitHub Actions CI/CD Pipeline

This document defines the production CI/CD flow for MilkyWay HomeLab.

## Branch strategy

Recommended production branch flow:

```text
feature/* -> dev -> pull request -> main (or master) -> production deploy
```

The production workflow should run on **push to `main` or `master`**, which in practice happens after the `dev` branch is merged.

## CI/CD goals

1. Rebuild only the services affected by a change.
2. Build **multi-arch** images for `linux/amd64` and `linux/arm64`.
3. Push images to **GHCR**.
4. Roll out the new images to K3s.
5. Verify the rollout status.
6. Report success or failure.

## Required GitHub Secrets

| Secret | Purpose |
|---|---|
| `KUBECONFIG_PROD` | Base64-encoded kubeconfig for the production K3s cluster |
| `GHCR_TOKEN` | Token with permission to push images to GHCR |
| `REGISTRY_USER` | GHCR username or GitHub actor used for registry login |

Optional secrets:

- `DISCORD_WEBHOOK_URL`
- `SLACK_WEBHOOK_URL`
- `PROD_SSH_HOST`, `PROD_SSH_USER`, `PROD_SSH_KEY` if you prefer SSH-based deploys

## Important ARM64 note for Chess

The current Chess game image in the test environment is not ready for ARM64 because it uses:

```text
STOCKFISH_VARIANT=x86-64-avx2
```

Before enabling the Chess game in production CI/CD, update the image build so the `linux/arm64` path uses an ARM-compatible Stockfish build. The workflow below assumes the Dockerfile has already been made multi-arch safe.

## Per-app pipeline design

Do **not** use one monolithic always-build-everything workflow. Use path filters so that only changed apps rebuild.

Example service/image mapping:

| Service | Image |
|---|---|
| `nebula-rest-prod` | `ghcr.io/milkyway-homelabs/nebula-rest-prod` |
| `nebula-front-prod` | `ghcr.io/milkyway-homelabs/nebula-front-prod` |
| `chess-rest-prod` | `ghcr.io/milkyway-homelabs/chess-rest-prod` |
| `chess-front-prod` | `ghcr.io/milkyway-homelabs/chess-front-prod` |
| `chess-game-prod` | `ghcr.io/milkyway-homelabs/chess-game-prod` |
| `hacman-rest-prod` | `ghcr.io/milkyway-homelabs/hacman-rest-prod` |
| `hacman-front-prod` | `ghcr.io/milkyway-homelabs/hacman-front-prod` |
| `hacman-game-prod` | `ghcr.io/milkyway-homelabs/hacman-game-prod` |

## Workflow file location

```text
.github/workflows/deploy-prod.yml
```

## Complete example `deploy-prod.yml`

```yaml
name: deploy-prod

on:
  push:
    branches:
      - main
      - master
    paths:
      - 'tomcat/**'
      - 'nginx/**'
      - 'kestrel/**'
      - 'django/**'
      - 'infrastructure/k8s/prod/**'
      - '.github/workflows/deploy-prod.yml'

permissions:
  contents: read
  packages: write

concurrency:
  group: prod-deploy
  cancel-in-progress: false

jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.matrix.outputs.matrix }}
      has_changes: ${{ steps.matrix.outputs.has_changes }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect changed services
        id: changes
        uses: dorny/paths-filter@v3
        with:
          filters: |
            nebula-rest:
              - 'tomcat/app/nebula-rest-api##latest.war'
              - 'tomcat/image/nebula/**'
              - 'tomcat/setenv/nebula/**'
            nebula-front:
              - 'nginx/nebula-front/**'
            chess-rest:
              - 'tomcat/app/chess-rest-api##latest.war'
              - 'tomcat/image/chess/**'
              - 'tomcat/setenv/chess/**'
            chess-front:
              - 'nginx/chess-front/**'
            chess-game:
              - 'django/chess-game-front/**'
            hacman-rest:
              - 'kestrel/hacman-app-back/**'
            hacman-front:
              - 'kestrel/hacman-app-front/**'
            hacman-game:
              - 'nginx/hacman-game/**'

      - name: Build matrix JSON
        id: matrix
        env:
          NEBULA_REST: ${{ steps.changes.outputs.nebula-rest }}
          NEBULA_FRONT: ${{ steps.changes.outputs.nebula-front }}
          CHESS_REST: ${{ steps.changes.outputs.chess-rest }}
          CHESS_FRONT: ${{ steps.changes.outputs.chess-front }}
          CHESS_GAME: ${{ steps.changes.outputs.chess-game }}
          HACMAN_REST: ${{ steps.changes.outputs.hacman-rest }}
          HACMAN_FRONT: ${{ steps.changes.outputs.hacman-front }}
          HACMAN_GAME: ${{ steps.changes.outputs.hacman-game }}
        run: |
          python3 - <<'PY'
          import json
          import os

          services = [
            {
              'flag': 'NEBULA_REST',
              'name': 'nebula-rest-prod',
              'context': 'tomcat/image/nebula',
              'dockerfile': 'tomcat/image/nebula/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/nebula-rest-prod',
              'deployment': 'nebula-rest-prod',
              'container': 'nebula-rest-prod'
            },
            {
              'flag': 'NEBULA_FRONT',
              'name': 'nebula-front-prod',
              'context': 'nginx/nebula-front',
              'dockerfile': 'nginx/nebula-front/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/nebula-front-prod',
              'deployment': 'nebula-front-prod',
              'container': 'nebula-front-prod'
            },
            {
              'flag': 'CHESS_REST',
              'name': 'chess-rest-prod',
              'context': 'tomcat/image/chess',
              'dockerfile': 'tomcat/image/chess/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/chess-rest-prod',
              'deployment': 'chess-rest-prod',
              'container': 'chess-rest-prod'
            },
            {
              'flag': 'CHESS_FRONT',
              'name': 'chess-front-prod',
              'context': 'nginx/chess-front',
              'dockerfile': 'nginx/chess-front/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/chess-front-prod',
              'deployment': 'chess-front-prod',
              'container': 'chess-front-prod'
            },
            {
              'flag': 'CHESS_GAME',
              'name': 'chess-game-prod',
              'context': 'django/chess-game-front',
              'dockerfile': 'django/chess-game-front/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/chess-game-prod',
              'deployment': 'chess-game-prod',
              'container': 'chess-game-prod'
            },
            {
              'flag': 'HACMAN_REST',
              'name': 'hacman-rest-prod',
              'context': 'kestrel/hacman-app-back',
              'dockerfile': 'kestrel/hacman-app-back/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/hacman-rest-prod',
              'deployment': 'hacman-rest-prod',
              'container': 'hacman-rest-prod'
            },
            {
              'flag': 'HACMAN_FRONT',
              'name': 'hacman-front-prod',
              'context': 'kestrel/hacman-app-front',
              'dockerfile': 'kestrel/hacman-app-front/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/hacman-front-prod',
              'deployment': 'hacman-front-prod',
              'container': 'hacman-front-prod'
            },
            {
              'flag': 'HACMAN_GAME',
              'name': 'hacman-game-prod',
              'context': 'nginx/hacman-game',
              'dockerfile': 'nginx/hacman-game/Dockerfile',
              'image': 'ghcr.io/milkyway-homelabs/hacman-game-prod',
              'deployment': 'hacman-game-prod',
              'container': 'hacman-game-prod'
            }
          ]

          include = [svc for svc in services if os.getenv(svc['flag']) == 'true']
          with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as fh:
            fh.write(f"matrix={json.dumps(include)}\n")
            fh.write(f"has_changes={'true' if include else 'false'}\n")
          PY

  build:
    needs: detect
    if: needs.detect.outputs.has_changes == 'true'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.detect.outputs.matrix) }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ secrets.REGISTRY_USER }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Build and push ${{ matrix.name }}
        uses: docker/build-push-action@v6
        with:
          context: ${{ matrix.context }}
          file: ${{ matrix.dockerfile }}
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ${{ matrix.image }}:${{ github.sha }}
            ${{ matrix.image }}:latest

  deploy:
    needs:
      - detect
      - build
    if: needs.detect.outputs.has_changes == 'true'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.detect.outputs.matrix) }}
    steps:
      - name: Set up kubectl
        uses: azure/setup-kubectl@v4

      - name: Write kubeconfig
        run: |
          mkdir -p "$RUNNER_TEMP/.kube"
          echo "${{ secrets.KUBECONFIG_PROD }}" | base64 -d > "$RUNNER_TEMP/.kube/config"

      - name: Roll out deployment
        env:
          KUBECONFIG: ${{ runner.temp }}/.kube/config
        run: |
          kubectl -n milkyway-apps set image deployment/${{ matrix.deployment }} \
            ${{ matrix.container }}=${{ matrix.image }}:${{ github.sha }}
          kubectl -n milkyway-apps rollout status deployment/${{ matrix.deployment }} --timeout=300s

  notify:
    needs:
      - build
      - deploy
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Print summary
        run: |
          echo "Build result: ${{ needs.build.result }}"
          echo "Deploy result: ${{ needs.deploy.result }}"
```

## SSH-based deployment alternative

If you do not want to store a kubeconfig in GitHub, deploy over SSH instead:

- store `PROD_SSH_HOST`, `PROD_SSH_USER`, `PROD_SSH_KEY` as GitHub Secrets
- use `appleboy/ssh-action` or plain `ssh`
- run `kubectl` on the Raspberry Pi itself

Example remote command:

```bash
kubectl -n milkyway-apps set image deployment/chess-rest-prod chess-rest-prod=ghcr.io/milkyway-homelabs/chess-rest-prod:${GITHUB_SHA}
kubectl -n milkyway-apps rollout status deployment/chess-rest-prod --timeout=300s
```

## Rollback

If a deployment goes bad:

```bash
kubectl -n milkyway-apps rollout undo deployment/chess-rest-prod
kubectl -n milkyway-apps rollout undo deployment/nebula-rest-prod
kubectl -n milkyway-apps rollout undo deployment/hacman-rest-prod
```

Also useful:

```bash
kubectl -n milkyway-apps rollout history deployment/chess-rest-prod
```

## Operational recommendations

- Protect `main`/`master` with pull requests only.
- Require the `dev` branch to merge through PRs.
- Keep images immutable by SHA tags even if you also push `latest`.
- For production manifests, prefer updating Deployments via `kubectl set image` or `helm upgrade`, not ad-hoc SSH copies.
- Verify rollout status before marking the workflow green.
