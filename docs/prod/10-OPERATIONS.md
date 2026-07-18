# Day-to-Day Operations

This document covers routine production operations for the MilkyWay HomeLab K3s cluster.

## 1. Updating an application

### Preferred: CI/CD-driven update

1. Merge `dev` into `main`/`master`.
2. Let GitHub Actions build the multi-arch image and push it to GHCR.
3. Let the deploy job update the Kubernetes Deployment.
4. Verify rollout success.

### Manual update

Example for Chess REST:

```bash
kubectl -n milkyway-apps set image deployment/chess-rest-prod chess-rest-prod=ghcr.io/milkyway-homelabs/chess-rest-prod:2026.07.18
kubectl -n milkyway-apps rollout status deployment/chess-rest-prod --timeout=300s
```

## 2. Checking logs

### Kubernetes logs

```bash
kubectl -n milkyway-apps get pods
kubectl -n milkyway-apps logs deploy/chess-rest-prod --tail=200
kubectl -n milkyway-apps logs deploy/nebula-rest-prod -f
kubectl -n milkyway-data logs statefulset/mariadb-prod --tail=200
```

### Grafana + Loki

Preferred for historical investigation:

- open `https://milkyway.lab/grafana/`
- use Loki for pod logs
- correlate with Prometheus metrics and restart counts

## 3. Scaling workloads

Scale stateless services up or down:

```bash
kubectl -n milkyway-apps scale deployment/nebula-front-prod --replicas=2
kubectl -n milkyway-apps scale deployment/hacman-front-prod --replicas=2
```

Stateful services should be scaled with care and only when the application supports it.

## 4. Database backup as a CronJob

A Kubernetes CronJob replaces the standalone Compose backup service.

Example manifest:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-prod
  namespace: milkyway-data
spec:
  schedule: "0 3 * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup-prod
              image: ghcr.io/milkyway-homelabs/backup-prod:latest
              envFrom:
                - secretRef:
                    name: backup-prod-secret
              volumeMounts:
                - name: backup-storage
                  mountPath: /backups
          volumes:
            - name: backup-storage
              persistentVolumeClaim:
                claimName: backup-prod-pvc
```

Run one immediately:

```bash
kubectl -n milkyway-data create job --from=cronjob/backup-prod backup-prod-manual-$(date +%s)
```

## 5. Certificate renewal

Renew the wildcard certificate before expiry:

1. regenerate the CSR
2. sign the new certificate with the Root CA
3. update the Kubernetes TLS secret
4. confirm Traefik serves the new certificate

Verification:

```bash
echo | openssl s_client -connect milkyway.lab:443 -servername milkyway.lab 2>/dev/null | openssl x509 -noout -dates -issuer -subject
```

## 6. Adding a new worker node

On the server node:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

On the new worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.100:6443 K3S_TOKEN=<token> sh -
```

Back on the server:

```bash
kubectl get nodes -o wide
kubectl label node worker-01 milkyway.io/role=worker
```

## 7. Adding a new application

Checklist:

1. Create GHCR image names with the `-prod` suffix.
2. Ensure `linux/arm64` images exist.
3. Add Deployment, Service, ConfigMap, Secret, and IngressRoute manifests.
4. Add NetworkPolicies.
5. Add DB access policy if needed.
6. Add monitoring dashboards and scrape config if applicable.
7. Add CI/CD path filters and deployment mapping.
8. Add DNS and route documentation updates.
9. Verify it does not bypass Nebula/Andromeda security rules.

## 8. Troubleshooting

| Problem | Checks | Likely fix |
|---|---|---|
| `kubectl get nodes` shows `NotReady` | `sudo systemctl status k3s`, `journalctl -u k3s -n 200 --no-pager` | fix disk pressure, cgroups, or network reachability |
| Traefik returns 404 | `kubectl -n milkyway-apps get ingressroute`, `kubectl -n milkyway-infra logs deploy/traefik` | route or middleware mismatch |
| TLS warning in browser | inspect CA trust, `openssl s_client`, SAN entries | install the Root CA on the client or regenerate the cert with correct SANs |
| Android cannot reach `milkyway.lab` | check Wi-Fi DNS, Pi-hole query log, Android Private DNS | point DNS to Pi-hole and disable conflicting Private DNS |
| Pod is `ImagePullBackOff` | `kubectl describe pod`, GHCR permissions | fix image tag, registry auth, or missing arm64 image |
| Pod is `OOMKilled` | `kubectl describe pod`, Prometheus memory graphs | increase memory limit or tune the app |
| PVC is `Pending` | `kubectl get storageclass`, `kubectl describe pvc` | check `local-path` or storage class name |
| Worker will not join | `journalctl -u k3s-agent -n 200 --no-pager` | verify token, port 6443, and hostname/DNS |
| Andromeda is publicly reachable | `kubectl get ingressroute -A | grep andromeda` | delete the route immediately |

## 9. Useful command cheat sheet

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A
kubectl get ingressroute -A
kubectl get networkpolicy -A
kubectl top pods -A
kubectl -n milkyway-apps rollout status deployment/nebula-rest-prod
kubectl -n milkyway-apps rollout restart deployment/chess-game-prod
kubectl -n milkyway-apps describe pod <pod-name>
kubectl -n milkyway-data get pvc
kubectl -n milkyway-monitoring port-forward svc/grafana 3000:3000
```

## 10. Operational habits that prevent pain

- Keep DNS, TLS, and K3s changes in Git.
- Do not commit `.env` files, kubeconfig files, CA private keys, or real passwords.
- Prefer SHA-tag deployments over `latest` when you need an exact rollback point.
- Keep Pi-hole outside the cluster.
- Keep Andromeda private.
- Test every image for `linux/arm64` before making it the production default.
- Monitor disk usage under `/mnt/nvme`; SQLite, Loki, and database volumes will grow quietly.
