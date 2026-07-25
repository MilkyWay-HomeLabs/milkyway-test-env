# Terraform Infrastructure as Code

This document defines the recommended Terraform layout for provisioning MilkyWay production resources in K3s.

## Versions and providers

- Terraform: **`>= 1.7`**
- Providers:
  - `hashicorp/kubernetes`
  - `hashicorp/helm`
  - `hashicorp/local`

## Recommended directory structure

```text
infrastructure/docker/prod/terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── modules/
│   ├── namespaces/
│   ├── networking/
│   ├── traefik/
│   ├── monitoring/
│   ├── databases/
│   └── apps/
└── environments/
    └── prod/
        └── terraform.tfvars
```

Suggested clone path on the Pi:

```text
/mnt/nvme/git/milkyway-test-env/infrastructure/docker/prod/terraform/
```

## Install Terraform on Debian 13

Install Terraform on the machine where the Terraform commands will run. For
the Raspberry Pi running Debian 13 (`trixie`):

```bash
sudo apt-get update
sudo apt-get install -y curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg

echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com trixie main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform
terraform version
```

Run `terraform init` only after changing into a directory containing the
Terraform `.tf` files. If `cd` reports `No such file or directory`, stop and
fix the project path first. The shell remains in the previous directory after
a failed `cd`, so running `terraform init` immediately afterwards can
accidentally initialize an empty home directory.

## Creating the Terraform project on the Pi

The directory above is a target location; Terraform does not create the
project files automatically. First put the repository containing the
`infrastructure/docker/prod/terraform/` directory on the Pi. For a repository with a
remote Git URL:

```bash
sudo mkdir -p /mnt/nvme/git
sudo chown admin:admin /mnt/nvme/git
git clone <REPOSITORY_URL> /mnt/nvme/git/milkyway-test-env
```

If the repository is already present, update it instead:

```bash
cd /mnt/nvme/git/milkyway-test-env
git pull
```

If the repository exists only on another computer, copy the production
directory to the same target path with `rsync` or `scp`. Then create the
Terraform layout:

```bash
cd /mnt/nvme/git/milkyway-test-env
mkdir -p infrastructure/docker/prod/terraform/modules/{namespaces,networking,traefik,monitoring,databases,apps}
mkdir -p infrastructure/docker/prod/terraform/environments/prod
cd infrastructure/docker/prod/terraform
```

Save the configuration examples in this document as the corresponding files:

```text
providers.tf
variables.tf
main.tf
modules/namespaces/main.tf
modules/networking/main.tf
modules/traefik/main.tf
environments/prod/terraform.tfvars
```

The `monitoring`, `databases`, and `apps` module directories can remain empty
until those workloads are added to `main.tf`. Terraform requires real `.tf`
files; creating only empty directories is not enough.

Before running Terraform, verify the working directory and kubeconfig:

```bash
cd /mnt/nvme/git/milkyway-test-env/infrastructure/docker/prod/terraform
test -f providers.tf && test -f variables.tf && test -f main.tf
test -f /home/admin/.kube/config
KUBECONFIG=/home/admin/.kube/config kubectl get nodes
```

Do not run `terraform apply` until `terraform plan` has been reviewed.

## What Terraform should own

Good Terraform targets in this project:

- namespaces
- labels and RBAC
- Helm releases
- TLS secrets
- NetworkPolicies
- ConfigMaps
- baseline Services and Deployments/StatefulSets

Keep real secret values outside versioned code.

## Example `providers.tf`

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
```

## Example `variables.tf`

```hcl
variable "kubeconfig_path" {
  type        = string
  description = "Absolute path to the kubeconfig used for the production cluster"
  default     = "/home/admin/.kube/config"
}

variable "domain" {
  type        = string
  description = "Primary production domain"
  default     = "milkyway.lab"
}

variable "traefik_tls_cert_path" {
  type        = string
  description = "Absolute path to the wildcard certificate"
  default     = "/mnt/nvme/k3s/traefik/certs/milkyway.lab.crt"
}

variable "traefik_tls_key_path" {
  type        = string
  description = "Absolute path to the wildcard private key"
  default     = "/mnt/nvme/k3s/traefik/certs/milkyway.lab.key"
}
```

## Root module example

```hcl
module "namespaces" {
  source = "./modules/namespaces"
}

module "traefik" {
  source                = "./modules/traefik"
  domain                = var.domain
  traefik_tls_cert_path = var.traefik_tls_cert_path
  traefik_tls_key_path  = var.traefik_tls_key_path
}

module "networking" {
  source = "./modules/networking"
}
```

## Example module: namespaces

`modules/namespaces/main.tf`

```hcl
locals {
  namespaces = {
    milkyway-infra      = "infra"
    milkyway-monitoring = "monitoring"
    milkyway-data       = "data"
    milkyway-apps       = "apps"
  }
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespaces

  metadata {
    name = each.key
    labels = {
      name                = each.key
      "milkyway.io/tier" = each.value
    }
  }
}
```

## Example module: Traefik Helm release

`modules/traefik/main.tf`

```hcl
variable "domain" {
  type = string
}

variable "traefik_tls_cert_path" {
  type = string
}

variable "traefik_tls_key_path" {
  type = string
}

resource "kubernetes_secret_v1" "traefik_tls" {
  metadata {
    name      = "milkyway-lab-tls"
    namespace = "milkyway-infra"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = filebase64(var.traefik_tls_cert_path)
    "tls.key" = filebase64(var.traefik_tls_key_path)
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = "milkyway-infra"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "41.0.2"

  values = [yamlencode({
    deployment = {
      podLabels = {
        "app.kubernetes.io/name" = "traefik"
      }
    }
    service = {
      type = "NodePort"
    }
    ports = {
      web = {
        nodePort = 30080
      }
      websecure = {
        nodePort = 30443
        tls = {
          enabled = true
        }
      }
    }
    ingressRoute = {
      dashboard = {
        enabled = true
      }
    }
  })]
}
```

If you deploy MetalLB, switch `service.type` to `LoadBalancer` and optionally assign a fixed IP.

## Example module: networking

Use Terraform for reusable NetworkPolicies.

```hcl
resource "kubernetes_network_policy_v1" "allow_auth_net" {
  metadata {
    name      = "allow-auth-net"
    namespace = "milkyway-apps"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "andromeda-auth-prod"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "nebula-rest-prod"
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 8080
      }
    }
  }
}
```

## Example environment variables file

File: `environments/prod/terraform.tfvars`

```hcl
kubeconfig_path       = "/home/admin/.kube/config"
domain                = "milkyway.lab"
traefik_tls_cert_path = "/mnt/nvme/k3s/traefik/certs/milkyway.lab.crt"
traefik_tls_key_path  = "/mnt/nvme/k3s/traefik/certs/milkyway.lab.key"
```

Do **not** commit real passwords or tokens in this file.

## State storage

### Option A — local state

Good enough for a home lab when one admin operates the cluster.

Example state location:

```text
/mnt/nvme/git/milkyway-test-env/infrastructure/docker/prod/terraform/terraform.tfstate
```

### Option B — remote state

Use S3-compatible storage such as **MinIO** if you want:

- team access
- state locking
- easier recovery from node replacement

For a home lab, local state is acceptable. Remote state is a convenience upgrade, not a requirement.

## Workflow

Run Terraform from the production module root:

```bash
cd /mnt/nvme/git/milkyway-test-env/infrastructure/docker/prod/terraform
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Handling sensitive values

Recommended options:

- `terraform.tfvars` kept out of Git
- environment variables such as `TF_VAR_db_password`
- generated Kubernetes Secrets from external files under `/mnt/nvme`

Example with environment variables:

```bash
export TF_VAR_db_password='change-me'
terraform apply -var-file=environments/prod/terraform.tfvars
```

Add these ignore rules in the repo root if they are not already present:

```gitignore
**/terraform.tfstate
**/terraform.tfstate.*
**/.terraform/
**/terraform.tfvars
```

## Recommended ownership split

| Tool | Owns |
|---|---|
| Ansible | OS, packages, K3s install, Pi-hole, certificates |
| Terraform | Namespaces, Helm releases, policies, services, workloads |
| GitHub Actions | Image build and rollout updates |

That split keeps responsibilities clean and avoids Terraform shelling into machines just to install the OS-level prerequisites.
