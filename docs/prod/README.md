# MilkyWay HomeLab Production Documentation

Production documentation for running the MilkyWay HomeLab stack on **K3s** with a **Raspberry Pi 5 (8 GB, ARM64, NVMe)** as the first control-plane node.

> Scope: this documentation translates the current Docker Compose test environment (`milkyway.test`) into a production-grade K3s deployment on `milkyway.lab`, while preserving the same application boundaries, naming convention, and Traefik path-based routing model.

## Table of contents

- [Quick-start order](#quick-start-order)
- [Prerequisites summary](#prerequisites-summary)
- [Technology stack overview](#technology-stack-overview)
- [Documentation index](#documentation-index)
- [Production opinions used throughout these docs](#production-opinions-used-throughout-these-docs)
- [Source of truth](#source-of-truth)

## Quick-start order

Read and execute the documents in this order:

1. [01-ARCHITECTURE.md](01-ARCHITECTURE.md) — understand the production topology, namespaces, network policies, and routing.
2. [02-HARDWARE-SETUP.md](02-HARDWARE-SETUP.md) — prepare the Raspberry Pi 5, NVMe storage, SSH, and local Docker.
3. [03-DNS-PIHOLE.md](03-DNS-PIHOLE.md) — make `milkyway.lab` resolve on the entire LAN, including Android devices.
4. [04-TLS-CERTIFICATES.md](04-TLS-CERTIFICATES.md) — create the internal Root CA and wildcard certificate for `*.milkyway.lab`.
5. [05-K3S-KUBERNETES.md](05-K3S-KUBERNETES.md) — install K3s, add namespaces, storage, Traefik, and worker nodes.
6. [07-ANSIBLE.md](07-ANSIBLE.md) — automate node provisioning and day-0 bootstrap.
7. [06-TERRAFORM.md](06-TERRAFORM.md) — define namespaces, Helm releases, policies, secrets, and workloads as code.
8. [09-K8S-MANIFESTS.md](09-K8S-MANIFESTS.md) — keep raw Kubernetes manifests for app-level objects and reference examples.
9. [08-CICD.md](08-CICD.md) — wire GitHub Actions to build multi-arch images and deploy to K3s.
10. [10-OPERATIONS.md](10-OPERATIONS.md) — daily operations, backup, troubleshooting, and scaling.

## Prerequisites summary

| Item | Recommendation |
|---|---|
| Primary node | Raspberry Pi 5, 8 GB RAM, ARM64, NVMe SSD |
| OS | Raspberry Pi OS 64-bit |
| LAN IP | Static DHCP reservation, example `192.168.0.100` |
| Storage mount | `/mnt/nvme` |
| Repo checkout | `/mnt/nvme/git/milkyway-test-env` |
| DNS | Pi-hole serving `milkyway.lab` and `*.milkyway.lab` |
| TLS | Internal Root CA + wildcard leaf cert |
| K8s distro | K3s with built-in Traefik disabled |
| IaC | Terraform `>= 1.7`, Ansible `>= 2.15` |
| CI/CD | GitHub Actions + GHCR + kubeconfig or SSH deploy |

## Technology stack overview

| Layer | Production choice | Why |
|---|---|---|
| Container orchestration | **K3s** | Lightweight, ARM64-native, multi-node capable, ideal for home lab scale |
| Ingress | **Traefik v3** | Matches the existing test environment and path-based routing model |
| DNS | **Pi-hole** | LAN-wide DNS control for `milkyway.lab`, visible to desktops and Android devices |
| Certificates | **OpenSSL-generated internal CA** | Full control for self-signed wildcard TLS inside the LAN |
| Infrastructure as Code | **Terraform** | Good fit for namespaces, Helm releases, secrets, services, and policies |
| Node provisioning | **Ansible** | Good fit for OS packages, storage, K3s install, Pi-hole setup, and cert generation |
| Image registry | **GitHub Container Registry** | Native to GitHub Actions and easy to secure with GitHub Secrets |
| CI/CD | **GitHub Actions** | Multi-arch builds, path filters, rollout status checks |

## Documentation index

| File | Purpose |
|---|---|
| [01-ARCHITECTURE.md](01-ARCHITECTURE.md) | Full production topology, namespaces, network policy mapping, routing, naming |
| [02-HARDWARE-SETUP.md](02-HARDWARE-SETUP.md) | Raspberry Pi 5 imaging, NVMe mount, SSH hardening, Docker, K3s prerequisites |
| [03-DNS-PIHOLE.md](03-DNS-PIHOLE.md) | Pi-hole deployment, wildcard DNS, router DHCP, Android setup, verification |
| [04-TLS-CERTIFICATES.md](04-TLS-CERTIFICATES.md) | Root CA, wildcard cert generation, Traefik integration, client trust steps |
| [05-K3S-KUBERNETES.md](05-K3S-KUBERNETES.md) | K3s install, worker-node joins, storage, namespaces, Traefik, NetworkPolicies |
| [06-TERRAFORM.md](06-TERRAFORM.md) | Terraform module structure, providers, workflow, Helm, TLS secrets |
| [07-ANSIBLE.md](07-ANSIBLE.md) | Inventory, playbooks, roles, important YAML snippets, vault usage |
| [08-CICD.md](08-CICD.md) | Branch strategy, secrets, multi-arch builds, deployment workflow, rollback |
| [09-K8S-MANIFESTS.md](09-K8S-MANIFESTS.md) | Raw manifest layout, naming, examples, resource limits, policy examples |
| [10-OPERATIONS.md](10-OPERATIONS.md) | Routine admin tasks, logs, scaling, backups, cert renewal, troubleshooting |

## Production opinions used throughout these docs

- **Pi-hole should run outside K3s** on the first node, usually as a standalone Docker container, so DNS still works if the cluster is down.
- **Traefik should be deployed by Helm/Terraform** instead of relying on the K3s bundled Traefik.
- **MetalLB is recommended** if you want a stable ingress virtual IP; otherwise use `NodePort` and point DNS to the first node.
- **Pod IPs are not part of the contract** in Kubernetes. Stable names come from Services and DNS, not fixed pod addresses.
- **The `-prod` suffix remains mandatory** for workload names, mirroring the current `-test` convention.
- **Andromeda stays private**: no public IngressRoute, no direct browser access, and no non-Nebula caller.
- **Chess game must be ARM-aware**: the current test Dockerfile uses `STOCKFISH_VARIANT=x86-64-avx2`; production must use an ARM64-compatible Stockfish build path before shipping to K3s.

## Source of truth

- Current test environment repository: `MilkyWay-HomeLabs/milkyway-test-env`
- Recommended production directories inside that repository:
  - `/mnt/nvme/git/milkyway-test-env/infrastructure/ansible/`
  - `/mnt/nvme/git/milkyway-test-env/infrastructure/terraform/prod/`
  - `/mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/`

Keep production configuration in Git. Never commit real secrets, CA private keys, `.env` files with passwords, or kubeconfig files.
