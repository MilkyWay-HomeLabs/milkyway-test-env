# Ansible Playbooks

This document describes the Ansible structure for provisioning the production Raspberry Pi node and future worker nodes.

## When to run Ansible

On a fresh host, run Ansible before Terraform. Ansible owns the operating
system and host-level prerequisites; Terraform owns resources inside the K3s
cluster.

For the current `rpi5-prod-01` host, K3s, the namespaces, Traefik, and the TLS
secret were already configured manually by following documents 04 and 05.
Do not run the complete playbook sequence below against this host blindly: it
may reinstall or alter components that are already working. First run any
relevant playbook with `--check --diff`, compare its intended state with the
current host, and then run only the missing or deliberately adopted tasks.

The recommended ownership split is:

| Area | Owner |
|---|---|
| OS packages, mounts, Docker, K3s installation | Ansible |
| Certificates generated on the host | Ansible or the documented manual process |
| Namespaces, Helm releases, TLS Secrets, NetworkPolicies and workloads | Terraform |
| Container image builds and rollout image updates | CI/CD |

Ansible should prepare the host; it should not invoke `terraform apply`. Run
Terraform separately from its production module directory and review
`terraform plan` before applying it.

## Version

- Ansible: **`>= 2.15`**

## Recommended directory structure

```text
infrastructure/ansible/
├── inventory/
│   └── prod/
│       ├── hosts.yml
│       └── group_vars/
│           ├── all.yml
│           └── k3s_server.yml
├── playbooks/
│   ├── 01-base-setup.yml
│   ├── 02-storage.yml
│   ├── 03-pihole.yml
│   ├── 04-k3s-server.yml
│   ├── 05-k3s-worker.yml
│   ├── 06-certs.yml
│   └── 07-deploy-apps.yml
└── roles/
    ├── common/
    ├── k3s_server/
    ├── k3s_worker/
    └── pihole/
```

## Inventory

File: `infrastructure/ansible/inventory/prod/hosts.yml`

```yaml
all:
  vars:
    ansible_user: admin
    ansible_python_interpreter: /usr/bin/python3
    milkyway_domain: milkyway.lab
    milkyway_ingress_ip: 192.168.0.100
    milkyway_nvme_mount: /mnt/nvme
  children:
    k3s_server:
      hosts:
        rpi5-prod-01:
          ansible_host: 192.168.0.100
    k3s_workers:
      hosts:
        worker-01:
          ansible_host: 192.168.0.110
```

File: `infrastructure/ansible/inventory/prod/group_vars/all.yml`

```yaml
timezone: Europe/Warsaw
pihole_upstream_dns:
  - 1.1.1.1
  - 1.0.0.1
repo_root: /mnt/nvme/git/milkyway-test-env
```

## Playbook overview

| Playbook | Main goal |
|---|---|
| `01-base-setup.yml` | OS updates, packages, swap disable, cgroups, Docker |
| `02-storage.yml` | NVMe partitioning, filesystem, mount, directories |
| `03-pihole.yml` | Standalone Pi-hole deployment and wildcard DNS config |
| `04-k3s-server.yml` | Install the K3s server on the Raspberry Pi |
| `05-k3s-worker.yml` | Join additional worker nodes |
| `06-certs.yml` | Generate internal CA and wildcard certificate |
| `07-deploy-apps.yml` | Apply manifests or kick Terraform/Kubectl deployment |

## 1. Base setup playbook

File: `playbooks/01-base-setup.yml`

```yaml
- name: Base OS setup
  hosts: all
  become: true
  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Upgrade packages
      ansible.builtin.apt:
        upgrade: dist

    - name: Install required packages
      ansible.builtin.apt:
        name:
          - curl
          - git
          - vim
          - jq
          - ca-certificates
          - nfs-common
          - open-iscsi
          - fail2ban
        state: present

    - name: Disable swap immediately
      ansible.builtin.command: swapoff -a
      changed_when: false

    - name: Comment swap entries in fstab
      ansible.builtin.replace:
        path: /etc/fstab
        regexp: '^(.*\sswap\s.*)$'
        replace: '# \1'

    - name: Ensure memory cgroup flags exist
      ansible.builtin.lineinfile:
        path: /boot/firmware/cmdline.txt
        backrefs: true
        regexp: '^(.*)$'
        line: '\1 cgroup_memory=1 cgroup_enable=memory'
```

## 2. Storage playbook

File: `playbooks/02-storage.yml`

```yaml
- name: Prepare NVMe storage
  hosts: k3s_server
  become: true
  tasks:
    - name: Create GPT partition
      community.general.parted:
        device: /dev/nvme0n1
        label: gpt
        number: 1
        state: present
        part_start: 1MiB
        part_end: 100%

    - name: Create ext4 filesystem
      community.general.filesystem:
        fstype: ext4
        dev: /dev/nvme0n1p1
        opts: -L milkyway-nvme

    - name: Create mount point
      ansible.builtin.file:
        path: /mnt/nvme
        state: directory
        mode: '0755'

    - name: Mount NVMe persistently
      ansible.posix.mount:
        path: /mnt/nvme
        src: LABEL=milkyway-nvme
        fstype: ext4
        opts: defaults,noatime
        state: mounted

    - name: Create required directories
      ansible.builtin.file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /mnt/nvme/git
        - /mnt/nvme/k3s/traefik/certs
        - /mnt/nvme/pihole
        - /mnt/nvme/backups
```

## 3. Pi-hole playbook

File: `playbooks/03-pihole.yml`

Key tasks:

- install Docker if missing
- render `/mnt/nvme/pihole/.env`
- render `/mnt/nvme/pihole/docker-compose.yml`
- render `/mnt/nvme/pihole/etc-dnsmasq.d/02-milkyway-lab.conf`
- run `docker compose up -d`

Important snippet:

```yaml
- name: Deploy Pi-hole compose file
  ansible.builtin.copy:
    dest: /mnt/nvme/pihole/docker-compose.yml
    mode: '0644'
    content: |
      services:
        pihole:
          image: pihole/pihole:latest
          container_name: pihole-prod
          restart: unless-stopped
          env_file:
            - /mnt/nvme/pihole/.env
          ports:
            - "53:53/tcp"
            - "53:53/udp"
            - "127.0.0.1:8081:80/tcp"
          volumes:
            - /mnt/nvme/pihole/etc-pihole:/etc/pihole
            - /mnt/nvme/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
          cap_add:
            - NET_ADMIN

- name: Start Pi-hole
  community.docker.docker_compose_v2:
    project_src: /mnt/nvme/pihole
    state: present
```

## 4. K3s server playbook

File: `playbooks/04-k3s-server.yml`

```yaml
- name: Install K3s server
  hosts: k3s_server
  become: true
  tasks:
    - name: Install K3s server
      ansible.builtin.shell: |
        curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb" sh -
      args:
        creates: /usr/local/bin/k3s

    - name: Ensure kubeconfig directory exists
      ansible.builtin.file:
        path: /home/admin/.kube
        state: directory
        owner: admin
        group: admin
        mode: '0700'

    - name: Copy kubeconfig for user
      ansible.builtin.copy:
        src: /etc/rancher/k3s/k3s.yaml
        dest: /home/admin/.kube/config
        remote_src: true
        owner: admin
        group: admin
        mode: '0600'
```

Add a follow-up task to rewrite `127.0.0.1` to the real server IP.

## 5. K3s worker playbook

File: `playbooks/05-k3s-worker.yml`

Pattern:

1. read the server token from the server host
2. pass it to worker hosts
3. run the agent install command

Example snippet:

```yaml
- name: Read K3s token from server
  hosts: k3s_server
  become: true
  tasks:
    - name: Slurp node token
      ansible.builtin.slurp:
        src: /var/lib/rancher/k3s/server/node-token
      register: k3s_token_raw

    - name: Set token fact
      ansible.builtin.set_fact:
        k3s_token: "{{ k3s_token_raw.content | b64decode | trim }}"

- name: Join K3s workers
  hosts: k3s_workers
  become: true
  vars:
    k3s_server_url: https://192.168.0.100:6443
    k3s_token: "{{ hostvars['rpi5-prod-01']['k3s_token'] }}"
  tasks:
    - name: Install K3s agent
      ansible.builtin.shell: |
        curl -sfL https://get.k3s.io | K3S_URL={{ k3s_server_url }} K3S_TOKEN={{ k3s_token }} sh -
      args:
        creates: /usr/local/bin/k3s-agent
```

## 6. Certificate playbook

File: `playbooks/06-certs.yml`

Use either `community.crypto` modules or shell commands. A shell-based approach maps directly to the OpenSSL commands used elsewhere in the docs.

Important snippet:

```yaml
- name: Create certificate directory
  ansible.builtin.file:
    path: /mnt/nvme/k3s/traefik/certs
    state: directory
    mode: '0755'

- name: Write SAN extension file
  ansible.builtin.copy:
    dest: /mnt/nvme/k3s/traefik/certs/milkyway.lab.ext
    mode: '0644'
    content: |
      authorityKeyIdentifier=keyid,issuer
      basicConstraints=CA:FALSE
      keyUsage=digitalSignature,keyEncipherment
      extendedKeyUsage=serverAuth
      subjectAltName=@alt_names

      [alt_names]
      DNS.1=milkyway.lab
      DNS.2=*.milkyway.lab
      IP.1=192.168.0.100
```

## 7. Deploy apps playbook

File: `playbooks/07-deploy-apps.yml`

This playbook may apply raw manifests when Ansible is the chosen deployment
owner. If Terraform owns the cluster objects, do not make this playbook invoke
Terraform; run Terraform separately so its state remains in the expected
working directory.

Example direct `kubectl` pattern:

```yaml
- name: Deploy MilkyWay applications
  hosts: k3s_server
  become: false
  tasks:
    - name: Apply production manifests
      ansible.builtin.shell: |
        kubectl apply -f /mnt/nvme/git/milkyway-test-env/infrastructure/k8s/prod/
```

If Terraform owns the cluster objects, omit this playbook or use it only for
host-level preparation.

## Secrets with Ansible Vault

Use Vault for:

- Pi-hole admin password
- database passwords
- GitHub deploy keys
- any API keys used by automation

Create a vault file:

```bash
ansible-vault create /mnt/nvme/git/milkyway-test-env/infrastructure/ansible/inventory/prod/group_vars/all/vault.yml
```

Edit it later:

```bash
ansible-vault edit /mnt/nvme/git/milkyway-test-env/infrastructure/ansible/inventory/prod/group_vars/all/vault.yml
```

Example contents:

```yaml
vault_pihole_webpassword: change-me
vault_mariadb_root_password: change-me
vault_postgres_password: change-me
```

## Running playbooks on a fresh host

The following sequence is for a new host that has not already been configured.
It is not a safe recovery procedure for the current manually configured
`rpi5-prod-01` until each playbook has been reviewed with `--check --diff`.

```bash
cd /mnt/nvme/git/milkyway-test-env/infrastructure/ansible
ansible-playbook -i inventory/prod/hosts.yml playbooks/01-base-setup.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/02-storage.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/03-pihole.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/04-k3s-server.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/06-certs.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/07-deploy-apps.yml
```

Join workers later with:

```bash
ansible-playbook -i inventory/prod/hosts.yml playbooks/05-k3s-worker.yml
```

## Recommended execution order

1. `01-base-setup.yml`
2. `02-storage.yml`
3. `03-pihole.yml`
4. `06-certs.yml`
5. `04-k3s-server.yml`
6. `07-deploy-apps.yml`
7. `05-k3s-worker.yml` when new nodes are added
