# TLS Certificates for Traefik

This directory contains TLS certificates used by Traefik. Production files (original) are ignored by git (`.gitignore`).

To run the environment, you must provide your own certificates:

## Option 1: Own certificates (e.g. from CA or Let's Encrypt)

Upload your files to this directory and name them according to the configuration in `traefik/config/dynamic.yml`:

- `milkyway.crt`
- `milkyway.key`

## Option 2: Generate a self-signed certificate (for testing purposes)

You can generate a self-signed certificate using OpenSSL:

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout milkyway.key \
    -out milkyway.crt \
    -subj "/C=PL/ST=Test/L=Test/O=MilkyWay/CN=*.test.milkyway" \
    -addext "subjectAltName=DNS:*.test.milkyway,DNS:test.milkyway,DNS:*.dev.milkyway,DNS:dev.milkyway"
This will generate:

- `milkyway.key` - Private key file
- `milkyway.crt` - Certificate file

Both files will be valid for 365 days and cover the `*.test.milkyway` and `*.dev.milkyway` domains.
