# Pi-hole DNS Setup

This guide makes **`milkyway.lab`** resolvable on the whole LAN, including Android phones on Wi-Fi.

## Recommendation: run Pi-hole outside K3s

Pi-hole can run either:

1. **as a standalone Docker container on the Raspberry Pi**
2. **as a pod inside K3s**

**Recommended choice: standalone Docker.**

Why:

- DNS keeps working even if K3s is down.
- You avoid a circular dependency where the cluster needs DNS to recover, but DNS itself lives in the cluster.
- Publishing ports `53/tcp` and `53/udp` is simpler outside Kubernetes.

## Deployment options

| Option | Use it when | Trade-off |
|---|---|---|
| Standalone Docker on the RPi | You want maximum reliability | Best choice for this home lab |
| Pi-hole pod in `milkyway-infra` | You want everything in Kubernetes | DNS disappears when K3s is unavailable |

## Port strategy

On the same node, Traefik usually owns `:80` and `:443`. Because of that, the cleanest production arrangement is:

- Pi-hole DNS on `53/tcp` and `53/udp`
- Pi-hole admin UI exposed internally on `127.0.0.1:8081`
- Traefik publishes the admin UI externally as `https://pihole.milkyway.lab/admin/`

Directly binding Pi-hole to `80:80` only works if:

- Pi-hole is on a separate host, or
- Pi-hole has its own dedicated IP/macvlan address, or
- you are not running Traefik on the same node

## 1. Create the Pi-hole working directory

```bash
sudo mkdir -p /mnt/nvme/pihole/{etc-pihole,etc-dnsmasq.d}
sudo chown -R wolf:wolf /mnt/nvme/pihole
```

## 2. Create the Pi-hole `.env`

File: `/mnt/nvme/pihole/.env`

```dotenv
TZ=Europe/Warsaw
PIHOLE_DNS_=1.1.1.1;1.0.0.1
WEBPASSWORD=change-this-now
VIRTUAL_HOST=pihole.milkyway.lab
FTLCONF_LOCAL_IPV4=192.168.0.100
```

Notes:

- `PIHOLE_DNS_` defines the upstream resolvers Pi-hole will forward to.
- `WEBPASSWORD` is the admin password; never commit the real value.
- `VIRTUAL_HOST` helps Pi-hole generate correct links.
- `FTLCONF_LOCAL_IPV4` should match the Raspberry Pi's LAN IP.

## 3. Create the standalone Docker Compose file

File: `/mnt/nvme/pihole/docker-compose.yml`

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole-prod
    restart: unless-stopped
    env_file:
      - /mnt/nvme/pihole/.env
    environment:
      TZ: ${TZ}
      PIHOLE_DNS_: ${PIHOLE_DNS_}
      WEBPASSWORD: ${WEBPASSWORD}
      VIRTUAL_HOST: ${VIRTUAL_HOST}
      FTLCONF_LOCAL_IPV4: ${FTLCONF_LOCAL_IPV4}
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "127.0.0.1:8081:80/tcp"
    volumes:
      - /mnt/nvme/pihole/etc-pihole:/etc/pihole
      - /mnt/nvme/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
```

Start it:

```bash
cd /mnt/nvme/pihole
docker compose up -d
docker ps --filter name=pihole-prod
```

## 4. Configure local DNS records

### Root record in the Pi-hole UI

Open the admin UI locally:

- `http://127.0.0.1:8081/admin/` from the Pi itself, or
- through Traefik later as `https://pihole.milkyway.lab/admin/`

In the Pi-hole admin UI:

- go to **Local DNS -> DNS Records**
- add `milkyway.lab` -> `192.168.0.100`

### Wildcard record for `*.milkyway.lab`

Pi-hole does not expose wildcard A records directly in the normal UI. Use a custom `dnsmasq` file instead.

File: `/mnt/nvme/pihole/etc-dnsmasq.d/02-milkyway-lab.conf`

```ini
address=/milkyway.lab/192.168.0.100
address=/.milkyway.lab/192.168.0.100
```

Reload Pi-hole DNS:

```bash
docker exec pihole-prod pihole restartdns
```

Result:

- `milkyway.lab` resolves to `192.168.0.100`
- `pihole.milkyway.lab`, `grafana.milkyway.lab`, or any other `*.milkyway.lab` host also resolves to `192.168.0.100`

## 5. Router configuration

In the router's DHCP settings, set the **primary DNS server** to:

```text
192.168.0.100
```

If the router allows a secondary DNS server, either:

- leave it empty, or
- use the same Pi-hole IP again

Do **not** point clients directly to a public resolver as backup, or they may bypass Pi-hole and your local `milkyway.lab` zone stops resolving.

## 6. Android configuration

The most reliable Android setup is still router-driven DHCP, but manual setup also works.

### Preferred: router pushes Pi-hole by DHCP

- Connect the phone to Wi-Fi.
- Renew the DHCP lease or reconnect to the network.
- Verify that the DNS server is the Pi IP.

### Manual Android Wi-Fi DNS

1. Open **Settings -> Network & Internet -> Internet**.
2. Tap the current Wi-Fi network.
3. Tap **Modify** or the pencil icon.
4. Open **Advanced options**.
5. Set **IP settings** to **Static**.
6. Keep the existing IP/gateway values.
7. Set **DNS 1** to `192.168.0.100`.
8. Optionally set **DNS 2** to `192.168.0.100` again.
9. Save and reconnect.

### Android Private DNS warning

Android **Private DNS** (DNS-over-TLS) can override Wi-Fi DNS and bypass Pi-hole.

Check:

1. **Settings -> Network & Internet -> Private DNS**
2. Either set it to **Off/Automatic** if your LAN DNS should win
3. Or configure a local DoT endpoint only if you actually provide one

For this home lab, the simplest reliable choice is usually **Private DNS Off** while connected to the LAN.

## 7. Optional Traefik route for the Pi-hole UI

If Traefik runs on the same node, expose Pi-hole as:

- `https://pihole.milkyway.lab/admin/`

Traefik can forward that request to `http://192.168.0.100:8081`.

This gives you:

- TLS from the wildcard cert
- consistent browser access from all clients
- no need to let Pi-hole own port `80` directly

## 8. Verification

Run these checks from another LAN client:

```bash
nslookup milkyway.lab 192.168.0.100
nslookup grafana.milkyway.lab 192.168.0.100
dig @192.168.0.100 milkyway.lab
dig @192.168.0.100 pihole.milkyway.lab
```

Expected result: all names resolve to `192.168.0.100` (or your ingress VIP if you later move to MetalLB and update the records).

## 9. Persistence across reboots

Pi-hole stays persistent because:

- config is stored under `/mnt/nvme/pihole`
- the container uses `restart: unless-stopped`
- the NVMe mount survives reboot through `/etc/fstab`

Validate reboot behavior:

```bash
sudo reboot
```

After the node returns:

```bash
docker ps --filter name=pihole-prod
dig @192.168.0.100 milkyway.lab
```

## 10. If you really want Pi-hole inside Kubernetes

It can live in the `milkyway-infra` namespace, but only do this if you accept the trade-off that a broken cluster means broken DNS. If you take that path:

- keep the `milkyway-infra` namespace small and stable
- use a `hostNetwork` or `NodePort` design carefully for port `53`
- still keep `/mnt/nvme/pihole` as the persistent storage root

For this project, **standalone Docker remains the recommended production design**.
