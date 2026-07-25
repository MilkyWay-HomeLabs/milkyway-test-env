# Raspberry Pi 5 Hardware Setup

This guide prepares the first production node: a **Raspberry Pi 5 (8 GB RAM)** running **Raspberry Pi OS 64-bit** with the MilkyWay production storage mounted on **`/mnt/nvme`**.

> Assumptions used below:
> - LAN IP reserved for the first node: `192.168.0.100`
> - SSH user: `admin`
> - Repository checkout path: `/mnt/nvme/git/milkyway-test-env`
> - NVMe device: `/dev/nvme0n1`

## 1. Install Raspberry Pi OS 64-bit

1. Use **Raspberry Pi Imager**.
2. Select **Raspberry Pi OS Lite (64-bit)** or the full **Raspberry Pi OS (64-bit)** if you want a desktop.
3. In the imager advanced settings:
   - set hostname to `rpi5-prod-01`
   - enable SSH
   - add your public key
   - set locale, keyboard, and timezone
4. Boot the Pi and update the base system:

```bash
ssh admin@192.168.0.100
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install -y curl git vim jq ca-certificates gnupg lsb-release nfs-common open-iscsi
sudo reboot
```

## 2. Prepare the NVMe SSD

Confirm the device first:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

Create a GPT partition table and one ext4 partition on `/dev/nvme0n1`:

```bash
sudo parted /dev/nvme0n1 --script mklabel gpt
sudo parted /dev/nvme0n1 --script mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L milkyway-nvme /dev/nvme0n1p1
```

Create the mount point and mount it:

```bash
sudo mkdir -p /mnt/nvme
sudo mount /dev/nvme0n1p1 /mnt/nvme
```

Persist the mount across reboots:

```bash
sudo blkid /dev/nvme0n1p1
```

Example `/etc/fstab` line:

```fstab
UUID=<replace-with-blkid-uuid>  /mnt/nvme  ext4  defaults,noatime  0  2
```

Apply and verify:

```bash
sudo mount -a
df -h /mnt/nvme
```

Create the core directory layout immediately:

```bash
sudo mkdir -p /mnt/nvme/{git,k3s/traefik/certs,pihole,etc,backups}
sudo chown -R admin:admin /mnt/nvme
```

## 3. Reserve a static IP on the router

**Recommended:** keep the Pi on DHCP but create a **DHCP reservation** in the router for the Pi's MAC address.

Why this is better than hard-coding the IP on the OS:

- DNS and client devices always see the same address.
- Reinstalling the Pi does not require editing its network config.
- Pi-hole and Traefik keep the same LAN endpoint.

Record these values in your router:

- Hostname: `rpi5-prod-01`
- Reserved IP: `192.168.0.100`
- DNS server later: `192.168.0.100` (after Pi-hole is installed)

## 4. Harden SSH

Create a dedicated SSH hardening file instead of editing the stock one:

```bash
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/99-milkyway.conf >/dev/null <<'EOF2'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
X11Forwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
EOF2
sudo sshd -t
sudo systemctl reload ssh
```

Add your public key if it was not injected during imaging:

```bash
mkdir -p /home/admin/.ssh
chmod 700 /home/admin/.ssh
cat >> /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys
```

Optional but sensible extras:

```bash
sudo apt-get install -y fail2ban
sudo systemctl enable --now fail2ban
```

## 5. Install Docker for local testing

K3s uses **containerd**, not Docker, but Docker is still useful for:

- running Pi-hole outside the cluster
- validating local images
- doing one-off `docker compose` tests on the production node

Install Docker:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker admin
sudo systemctl enable --now docker
```

Log out and back in, then verify:

```bash
docker version
docker compose version
```

## 6. K3s pre-installation requirements

### Disable swap

K3s is happiest with swap disabled.

```bash
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab
free -h
```

### Enable memory cgroups

Check the current kernel command line:

```bash
cat /boot/firmware/cmdline.txt
```

Ensure it contains these flags on the same line:

```text
cgroup_memory=1 cgroup_enable=memory
```

If missing, append them:

```bash
sudo sed -i '1 s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt
sudo reboot
```

After reboot, verify:

```bash
grep cgroup /proc/cmdline
```

### Basic kernel and runtime checks

```bash
uname -m
getconf LONG_BIT
systemctl is-active docker
```

Expected output:

- `uname -m` -> `aarch64`
- `getconf LONG_BIT` -> `64`
- Docker active if you installed it for Pi-hole/testing

## 7. Recommended host preparation

Set timezone and hostname clearly:

```bash
sudo timedatectl set-timezone Europe/Warsaw
sudo hostnamectl set-hostname rpi5-prod-01
```

Clone the repo onto NVMe storage:

```bash
mkdir -p /mnt/nvme/git
git clone https://github.com/MilkyWay-HomeLabs/milkyway-test-env.git /mnt/nvme/git/milkyway-test-env
```

## 8. Ports to keep in mind

| Port | Service |
|---|---|
| 22/tcp | SSH |
| 53/tcp + 53/udp | Pi-hole DNS |
| 80/tcp | HTTP / Pi-hole admin or Traefik redirect |
| 443/tcp | Traefik HTTPS |
| 6443/tcp | K3s API server |
| 8472/udp | Flannel VXLAN between nodes |
| 10250/tcp | Kubelet |

If you later enable a firewall, open the K3s ports before joining workers.

## 9. Ready-for-K3s checklist

Before moving on to K3s, verify all of the following:

- Raspberry Pi OS 64-bit is fully updated.
- `/mnt/nvme` is mounted from the NVMe SSD.
- The node keeps the reserved IP `192.168.0.100`.
- SSH password login is disabled and key login works.
- Docker is installed and working.
- Swap is off.
- Memory cgroups are enabled.
- `nfs-common` and `open-iscsi` are installed for future storage options.

When this checklist is green, continue with [03-DNS-PIHOLE.md](03-DNS-PIHOLE.md) and [05-K3S-KUBERNETES.md](05-K3S-KUBERNETES.md).
