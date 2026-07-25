# Kubernetes Manifests Guide

This guide defines the raw manifest layout and gives production-ready examples for MilkyWay HomeLab on K3s.

## Recommended file structure

```text
infrastructure/k8s/prod/
├── namespaces/
├── traefik/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingressroute.yaml
│   └── tls-secret.yaml
├── monitoring/
├── databases/
│   ├── mariadb/
│   ├── postgres/
│   └── mongo/
└── apps/
    ├── andromeda/
    ├── nebula/
    ├── chess/
    ├── hacman/
    └── robak/
```

## Database secrets and MariaDB bootstrap

Database credentials must not be stored in this repository. Keep only an
example file such as:

```text
k8s/databases/mariadb/mariadb-prod.env.example
```

On the production node, create the real file outside the repository with mode
`0600`, then create/update the Kubernetes Secret from it:

```bash
sudo install -d -m 0700 /mnt/nvme/k3s/secrets
sudo install -m 0600 /path/to/mariadb-prod.env /mnt/nvme/k3s/secrets/mariadb-prod.env

sudo k3s kubectl -n milkyway-data create secret generic mariadb-prod-credentials \
  --from-env-file=/mnt/nvme/k3s/secrets/mariadb-prod.env \
  --dry-run=client -o yaml \
  | sudo k3s kubectl apply -f -
```

Apply the MariaDB workload only after the secret exists:

```bash
sudo k3s kubectl apply -f /mnt/nvme/git/milkyway-prod-env/k8s/databases/mariadb/mariadb-prod.yaml
```

The manifest creates an ARM64-compatible MariaDB StatefulSet, a `local-path`
PVC on `rpi5-prod-01`, the `mariadb-prod` service, and an idempotent bootstrap
Job. It creates empty production databases for Andromeda, Nebula, Chess, Robak,
Element, and Racer. Application schemas and seed data are applied separately;
test databases and test passwords must not be copied into production.

## Naming convention for production

Use the same rule as test, with a `-prod` suffix:

```text
<app>-<role>-prod
```

Examples:

- `andromeda-auth-prod`
- `nebula-rest-prod`
- `chess-rest-prod`
- `hacman-front-prod`
- `robak-game-prod`

Apply the same names consistently to:

- Deployment names
- container names
- Service names
- ConfigMaps and Secrets when practical
- Traefik routes and backend service references

## Route translation from `dynamic.yml`

Keep the production routing identical in behavior to the test environment, only changing the domain:

- `milkyway.test` -> `milkyway.lab`
- file-provider routers -> Traefik `IngressRoute`
- file-provider strip middlewares -> Traefik `Middleware`

**Do not add a public route for Andromeda.**

## Example manifests

The following examples are complete YAML documents you can split into separate files.

### Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: milkyway-apps
  labels:
    name: milkyway-apps
    milkyway.io/tier: apps
```

### ConfigMap for Chess REST

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: chess-rest-prod-config
  namespace: milkyway-apps
data:
  SPRING_PROFILES_ACTIVE: prod
  JAVA_OPTS: "-Xms512m -Xmx1g"
  NEBULA_BASE_URL: "http://nebula-rest-prod.milkyway-apps.svc.cluster.local:8080"
  IMAGE_AVATAR_PATH: "/app/fileserver/chess/avatars"
```

### Secret (example only, base64-encoded)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: chess-rest-prod-secret
  namespace: milkyway-apps
type: Opaque
data:
  DB_USERNAME: Y2hlc3NfdXNlcg==
  DB_PASSWORD: Y2hhbmdlLW1lLW5vdyE=
```

> Never commit real secrets. Use generated values, Sealed Secrets, External Secrets, or apply secrets out-of-band.

### Deployment: `chess-rest-prod`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chess-rest-prod
  namespace: milkyway-apps
  labels:
    app.kubernetes.io/name: chess-rest-prod
    milkyway.io/app: chess
    milkyway.io/role: rest
    milkyway.io/ingress-access: "true"
    milkyway.io/db: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: chess-rest-prod
  template:
    metadata:
      labels:
        app.kubernetes.io/name: chess-rest-prod
        milkyway.io/app: chess
        milkyway.io/role: rest
        milkyway.io/ingress-access: "true"
        milkyway.io/db: mariadb
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
        - name: chess-rest-prod
          image: ghcr.io/milkyway-homelabs/chess-rest-prod:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              name: http
          envFrom:
            - configMapRef:
                name: chess-rest-prod-config
            - secretRef:
                name: chess-rest-prod-secret
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: http
            initialDelaySeconds: 20
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: http
            initialDelaySeconds: 60
            periodSeconds: 20
```

### Service: `chess-rest-prod`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: chess-rest-prod
  namespace: milkyway-apps
spec:
  selector:
    app.kubernetes.io/name: chess-rest-prod
  ports:
    - name: http
      port: 8080
      targetPort: http
  type: ClusterIP
```

### Traefik Middleware: `strip-chess`

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-chess
  namespace: milkyway-apps
spec:
  stripPrefix:
    prefixes:
      - /chess
```

### Traefik IngressRoute for Chess

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: chess-prod
  namespace: milkyway-apps
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`milkyway.lab`) && PathPrefix(`/chess/api`)
      kind: Rule
      middlewares:
        - name: strip-chess
      services:
        - name: chess-rest-prod
          port: 8080
    - match: Host(`milkyway.lab`) && PathPrefix(`/chess/app/`)
      kind: Rule
      services:
        - name: chess-front-prod
          port: 80
    - match: Host(`milkyway.lab`) && PathPrefix(`/chess/game/`)
      kind: Rule
      middlewares:
        - name: strip-chess-game
      services:
        - name: chess-game-prod
          port: 80
  tls:
    secretName: milkyway-lab-tls
```

### Middleware for Chess game path stripping

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-chess-game
  namespace: milkyway-apps
spec:
  stripPrefix:
    prefixes:
      - /chess/game
```

### NetworkPolicy: allow ingress from Traefik

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-traefik
  namespace: milkyway-apps
spec:
  podSelector:
    matchLabels:
      milkyway.io/ingress-access: "true"
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: milkyway-infra
          podSelector:
            matchLabels:
              app.kubernetes.io/name: traefik
```

### NetworkPolicy: allow internal DB traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal-mariadb
  namespace: milkyway-data
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: mariadb-prod
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: milkyway-apps
          podSelector:
            matchLabels:
              milkyway.io/db: mariadb
      ports:
        - protocol: TCP
          port: 3306
```

### NetworkPolicy: auth-net equivalent

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-auth-net
  namespace: milkyway-apps
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: andromeda-auth-prod
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: nebula-rest-prod
      ports:
        - protocol: TCP
          port: 8080
```

### PVC example for MariaDB

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-prod-data
  namespace: milkyway-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: local-path
```

## Resource limits for Raspberry Pi 5 (8 GB)

These are conservative starting points, not hard laws.

| Service | Requests CPU | Limits CPU | Requests Memory | Limits Memory |
|---|---:|---:|---:|---:|
| `andromeda-auth-prod` | 250m | 1 | 512Mi | 1Gi |
| `nebula-rest-prod` | 250m | 1 | 512Mi | 1Gi |
| `nebula-front-prod` | 50m | 200m | 64Mi | 128Mi |
| `chess-rest-prod` | 500m | 1 | 512Mi | 1Gi |
| `chess-front-prod` | 50m | 200m | 64Mi | 128Mi |
| `chess-game-prod` | 250m | 1 | 512Mi | 1Gi |
| `hacman-rest-prod` | 250m | 750m | 256Mi | 512Mi |
| `hacman-front-prod` | 100m | 500m | 128Mi | 256Mi |
| `hacman-game-prod` | 50m | 150m | 64Mi | 128Mi |
| `robak-rest-prod` | 250m | 1 | 512Mi | 1Gi |
| `robak-front-prod` | 50m | 200m | 64Mi | 128Mi |
| `robak-game-prod` | 50m | 150m | 64Mi | 128Mi |
| `mariadb-prod` | 500m | 1500m | 1Gi | 2Gi |
| `postgres-prod` | 500m | 1500m | 1Gi | 2Gi |
| `mongo-prod` | 250m | 1 | 512Mi | 1Gi |
| `traefik` | 100m | 250m | 128Mi | 256Mi |

## ARM64 notes by workload

- Hacman images are already based on `.NET ASP.NET` ARM64-capable base images.
- Nginx and Traefik images have ARM64 variants.
- MariaDB, PostgreSQL, MongoDB, Prometheus, Grafana, Loki, and Promtail all need ARM64-capable tags, which are available in mainstream images.
- **Chess game requires special care** because the current Stockfish download path is x86-specific.

## Apply order for raw manifests

```bash
kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/namespaces/
kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/traefik/
kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/databases/
kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/monitoring/
kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/apps/
```
