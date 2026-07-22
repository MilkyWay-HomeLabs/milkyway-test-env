# Self-Signed CA and Wildcard Certificate

This guide creates:

- one internal **Root CA** valid for 10 years
- one wildcard certificate for **`*.milkyway.lab`** valid for 2 years

All files live under:

```text
/mnt/nvme/k3s/traefik/certs/
```

> Browser warning reminder: self-signed TLS will still trigger warnings until every client trusts the Root CA. Trusting the leaf certificate alone is not enough; trust the **CA certificate** on each client platform.

## 1. Create the certificate directory

```bash
sudo mkdir -p /mnt/nvme/k3s/traefik/certs
sudo chown -R wolf:wolf /mnt/nvme/k3s/traefik/certs
```

## 2. Generate the Root CA (4096-bit RSA, 10 years)

```bash
openssl genrsa -out /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.key 4096
openssl req -x509 -new -nodes \
  -key /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.key \
  -sha256 -days 3650 \
  -out /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt \
  -subj "/C=PL/ST=HomeLab/L=HomeLab/O=MilkyWay HomeLab/CN=MilkyWay HomeLab Root CA"
```

Protect the private key:

```bash
chmod 600 /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.key
chmod 644 /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt
```

## 3. Create the SAN extensions file for `milkyway.lab`

File: `/mnt/nvme/k3s/traefik/certs/milkyway.lab.ext`

```ini
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

Use the actual ingress IP if it differs from `192.168.0.100`.

## 4. Generate the wildcard private key and CSR (2048-bit RSA)

```bash
openssl genrsa -out /mnt/nvme/k3s/traefik/certs/milkyway.lab.key 2048
openssl req -new \
  -key /mnt/nvme/k3s/traefik/certs/milkyway.lab.key \
  -out /mnt/nvme/k3s/traefik/certs/milkyway.lab.csr \
  -subj "/C=PL/ST=HomeLab/L=HomeLab/O=MilkyWay HomeLab/CN=milkyway.lab"
```

## 5. Sign the wildcard certificate (2 years)

```bash
openssl x509 -req \
  -in /mnt/nvme/k3s/traefik/certs/milkyway.lab.csr \
  -CA /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt \
  -CAkey /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.key \
  -CAcreateserial \
  -out /mnt/nvme/k3s/traefik/certs/milkyway.lab.crt \
  -days 730 -sha256 \
  -extfile /mnt/nvme/k3s/traefik/certs/milkyway.lab.ext
```

Verify the result:

```bash
openssl x509 -in /mnt/nvme/k3s/traefik/certs/milkyway.lab.crt -text -noout
```

Confirm that:

- CN is `milkyway.lab`
- SAN contains `milkyway.lab`
- SAN contains `*.milkyway.lab`
- SAN contains `192.168.0.100`

## 6. Use the certificate with Traefik

### Option A — Kubernetes TLS Secret (recommended)

```bash
kubectl create namespace milkyway-infra --dry-run=client -o yaml | kubectl apply -f -
kubectl -n milkyway-infra create secret tls milkyway-lab-tls \
  --cert=/mnt/nvme/k3s/traefik/certs/milkyway.lab.crt \
  --key=/mnt/nvme/k3s/traefik/certs/milkyway.lab.key \
  --dry-run=client -o yaml | kubectl apply -f -
```

Reference it from Traefik CRDs:

```yaml
tls:
  secretName: milkyway-lab-tls
```

### Option B — Traefik file provider

If you prefer file-based cert loading, mount `/mnt/nvme/k3s/traefik/certs` into the Traefik pod and add:

```yaml
tls:
  certificates:
    - certFile: /certs/milkyway.lab.crt
      keyFile: /certs/milkyway.lab.key
```

For Kubernetes-native management, **Option A is cleaner**.

## 7. Distribute the Root CA to clients

The file to distribute is:

```text
/mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt
```

### Linux

#### Debian / Ubuntu

```bash
sudo cp /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt /usr/local/share/ca-certificates/milkyway-root-ca.crt
sudo update-ca-certificates
```

#### Fedora

```bash
sudo cp /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt /etc/pki/ca-trust/source/anchors/milkyway-root-ca.crt
sudo update-ca-trust
```

#### Arch Linux

```bash
sudo trust anchor /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt
```

### macOS

1. Open **Keychain Access**.
2. Import `milkyway-root-ca.crt` into the **System** keychain.
3. Open the certificate.
4. Set **Trust -> When using this certificate** to **Always Trust**.

CLI alternative:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt
```

### Windows

1. Double-click `milkyway-root-ca.crt`.
2. Choose **Install Certificate**.
3. Select **Local Machine**.
4. Place it in **Trusted Root Certification Authorities**.
5. Finish the wizard and reopen the browser.

PowerShell alternative:

```powershell
Import-Certificate -FilePath C:\path\to\milkyway-root-ca.crt -CertStoreLocation Cert:\LocalMachine\Root
```

### Android

1. Copy `milkyway-root-ca.crt` to the phone.
2. Open **Settings -> Security & privacy -> More security settings -> Encryption & credentials -> Install a certificate**.
3. Choose **CA certificate** or **User certificate** depending on the Android version.
4. Select `milkyway-root-ca.crt`.
5. Confirm the warning.
6. Reopen Chrome or your browser and test `https://milkyway.lab`.

Important Android caveats:

- User-installed CAs may not be trusted by every native app.
- Browsers used for this home lab generally work once the CA is installed.
- If the phone still cannot resolve `milkyway.lab`, check Android **Private DNS** settings and Pi-hole DNS first; TLS trust alone is not enough.

## 8. Serve the CA certificate for easy phone download

The easiest ad-hoc method is a tiny HTTP server on the Pi:

```bash
cd /mnt/nvme/k3s/traefik/certs
python3 -m http.server 8082 --bind 0.0.0.0
```

Then browse from the phone to:

```text
http://192.168.0.100:8082/milkyway-root-ca.crt
```

Better long-term options:

- expose the certificate through Pi-hole/Traefik under `https://pihole.milkyway.lab/ca/`
- store it in a tiny static download site on the fileserver

## 9. Renewal process

Renew the wildcard certificate before it expires:

1. keep the same Root CA unless it was compromised
2. generate a new leaf key and CSR
3. sign a new leaf certificate
4. update the Kubernetes TLS secret
5. restart or reload Traefik if required
6. verify in a browser and with `openssl s_client`

Example renewal commands:

```bash
rm -f /mnt/nvme/k3s/traefik/certs/milkyway.lab.csr
openssl req -new \
  -key /mnt/nvme/k3s/traefik/certs/milkyway.lab.key \
  -out /mnt/nvme/k3s/traefik/certs/milkyway.lab.csr \
  -subj "/C=PL/ST=HomeLab/L=HomeLab/O=MilkyWay HomeLab/CN=milkyway.lab"
openssl x509 -req \
  -in /mnt/nvme/k3s/traefik/certs/milkyway.lab.csr \
  -CA /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.crt \
  -CAkey /mnt/nvme/k3s/traefik/certs/milkyway-root-ca.key \
  -CAcreateserial \
  -out /mnt/nvme/k3s/traefik/certs/milkyway.lab.crt \
  -days 730 -sha256 \
  -extfile /mnt/nvme/k3s/traefik/certs/milkyway.lab.ext
kubectl -n milkyway-infra create secret tls milkyway-lab-tls \
  --cert=/mnt/nvme/k3s/traefik/certs/milkyway.lab.crt \
  --key=/mnt/nvme/k3s/traefik/certs/milkyway.lab.key \
  --dry-run=client -o yaml | kubectl apply -f -
```

Set a calendar reminder **60 days before expiry**.
