# K3s Installation and Configuration

This guide installs **K3s** as the production Kubernetes distribution for MilkyWay HomeLab.

## Why K3s on a Raspberry Pi 5

K3s fits this project well because it is:

- **ARM64-native**
- a single lightweight binary (roughly ~70 MB compressed download footprint)
- bundled with **containerd**
- easy to bootstrap on one node and expand to many
- small enough for a Raspberry Pi 5 without giving up standard Kubernetes APIs

For a home lab, K3s with the default **SQLite** datastore is perfectly acceptable for a **single server node**. Worker nodes can join without changing that. If you later add multiple control-plane nodes, revisit the datastore design.

## 1. Single-node install

The first node acts as both **server** and **worker**.

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb" sh -
```

Why these flags:

- `--disable traefik` because this project deploys its own **Traefik v3**
- `--disable servicelb` because you will use **MetalLB** or **NodePort** instead

Verify the install:

```bash
sudo systemctl status k3s --no-pager
sudo kubectl get nodes -o wide
```

Expected result: the Raspberry Pi node is `Ready`.

## 2. kubeconfig setup for remote kubectl

K3s writes the admin kubeconfig to:

```text
/etc/rancher/k3s/k3s.yaml
```

Copy it to the user account:

```bash
mkdir -p /home/wolf/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/wolf/.kube/config
sudo chown wolf:wolf /home/wolf/.kube/config
chmod 600 /home/wolf/.kube/config
```

Replace `127.0.0.1` with the server IP if you want to use it from another machine:

```bash
sed -i 's/127.0.0.1/192.168.0.100/' /home/wolf/.kube/config
```

Then from a remote admin workstation:

```bash
export KUBECONFIG=/absolute/path/to/copied/k3s.yaml
kubectl get nodes
```

## 3. Namespace structure

Create the production namespaces:

```bash
kubectl create namespace milkyway-infra --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace milkyway-monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace milkyway-data --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace milkyway-apps --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace milkyway-infra name=milkyway-infra --overwrite
kubectl label namespace milkyway-monitoring name=milkyway-monitoring --overwrite
kubectl label namespace milkyway-data name=milkyway-data --overwrite
kubectl label namespace milkyway-apps name=milkyway-apps --overwrite
```

Roles of each namespace:

- `milkyway-infra` — Traefik, Pi-hole if ever containerized, TLS/cert helpers
- `milkyway-monitoring` — Prometheus, Grafana, Loki, Promtail
- `milkyway-data` — MariaDB, PostgreSQL, MongoDB, backup jobs
- `milkyway-apps` — Andromeda, Nebula, Chess, Hacman, Robak

## 4. Deploy Traefik v3

Use Helm for Traefik so Terraform can manage it cleanly later.

Add the Helm repo:

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

Example install using NodePort:

```bash
helm upgrade --install traefik traefik/traefik \
  --namespace milkyway-infra \
  --create-namespace \
  --set deployment.podLabels.app\.kubernetes\.io/name=traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ingressRoute.dashboard.enabled=true
```

If you prefer a stable virtual IP, install **MetalLB** and switch Traefik to `LoadBalancer`.

## 5. Storage in K3s

K3s includes the **local-path provisioner** by default.

### When to use local-path

Use it when:

- the cluster currently has one durable node with NVMe
- your databases are staying on that first node for now
- simple recovery is more important than shared storage

### When to move beyond local-path

| Option | Use it when |
|---|---|
| NFS | You want simple shared storage across nodes |
| Longhorn | You want replicated block storage and can afford more RAM/CPU |

On an 8 GB Raspberry Pi, **start with `local-path`**. Move only when there is a real need.

## 6. Multi-node expansion

Additional nodes join as **workers**.

Get the server token on the K3s server:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Join a worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.100:6443 K3S_TOKEN=<token-from-server> sh -
```

Verify:

```bash
kubectl get nodes -o wide
```

### Label worker nodes for placement

Examples:

```bash
kubectl label node worker-01 milkyway.io/role=worker
kubectl label node rpi5-prod-01 milkyway.io/storage=nvme
kubectl label node worker-02 milkyway.io/arch=amd64
```

Use these labels for scheduling:

- databases pinned to the NVMe node
- ARM64-sensitive workloads pinned to ARM64 nodes when required
- general stateless frontends free to run anywhere compatible

## 7. Recommended placement rules

| Workload | Recommendation |
|---|---|
| Databases | Pin to the NVMe node first |
| Traefik | Run at least one replica on the server node; add more later if multiple ingress-capable nodes exist |
| Monitoring | Prefer the server node first, then spread if capacity grows |
| Chess game | Ensure the image is ARM64-capable before scheduling on the Pi |
| Hacman/Nebula/Robak frontends | Safe stateless candidates for worker-node spreading |

## 8. NetworkPolicy equivalents for the test networks

### `allow-from-traefik` — replaces `proxy`

This policy allows ingress only from Traefik to pods that should be reachable by HTTP.

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

### `allow-internal` — replaces `internal`

Use targeted policies that let backends talk to the database namespace and monitoring stack.

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

### `allow-auth-net` — replaces `auth-net`

Only Nebula REST may reach Andromeda.

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

Do **not** create a similar allow policy for Chess. The production design removes the test-environment deviation.

## 9. ARM64 image awareness

K3s on the Raspberry Pi schedules `linux/arm64` containers. That means:

- every production image must have an ARM64 variant
- GitHub Actions must build **multi-arch** images (`linux/amd64`, `linux/arm64`)
- the Chess game image must stop using the hard-coded `x86-64-avx2` Stockfish asset

For the Chess game image, the current test Dockerfile is not production-safe for the Pi. Update the build logic so that the ARM64 build path uses an ARM-compatible Stockfish binary or a source build.

## 10. Verification commands

```bash
kubectl get nodes -o wide
kubectl get ns
kubectl -n milkyway-infra get pods
kubectl -n milkyway-apps get deploy,svc
kubectl -n milkyway-data get pvc,pods
kubectl get networkpolicy -A
```

## 11. Recommended deployment order after K3s is up

1. Namespaces
2. Traefik
3. TLS secret
4. Databases + PVCs
5. Monitoring stack
6. Application backends
7. Frontends / game containers
8. NetworkPolicies
9. CI/CD integration
