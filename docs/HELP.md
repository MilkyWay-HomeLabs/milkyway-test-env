# HELP: Common Docker / Docker Compose commands

This is a short, practical cheat-sheet with the most commonly used Docker and Docker Compose commands. Commands are copy‑ready and ready to paste into your terminal.

## Basics: listing and status
- Show running containers:
  ```bash
  docker ps
  ```

- Show all containers (including stopped):
  ```bash
  docker ps -a
  ```

- Show images:
  ```bash
  docker images
  ```

- Show Compose services and their state (Docker Compose v2+):
  ```bash
  docker compose ps
  ```

## Logs and debugging
- View container logs (last lines):
  ```bash
  docker logs <container>
  docker logs -n 200 <container>
  ```

- Follow logs live:
  ```bash
  docker logs -f <container>
  ```

- Get logs since a given time:
  ```bash
  docker logs --since 10m <container>
  ```

- Using Compose (logs for all or a specific service):
  ```bash
  docker compose logs -f       # all services
  docker compose logs -f <service>
  ```

## Exec into a container / run commands
- Interactive shell (if `bash` present):
  ```bash
  docker exec -it <container> bash
  ```

- For Alpine images use `sh`:
  ```bash
  docker exec -it <container> sh
  ```

- Run a one-off tool in the project network (e.g. curl):
  ```bash
  docker run --rm --network proxy curlimages/curl:latest -v http://hacman-app-back:8080/v1/version
  ```

## Start / stop / restart (including Traefik)
- Stop a container:
  ```bash
  docker stop <container>
  ```

- Start a container:
  ```bash
  docker start <container>
  ```

- Restart (soft restart):
  ```bash
  docker restart <container>
  ```

- Restart Traefik (if run with Compose):
  ```bash
  docker compose restart traefik
  # or
  docker restart traefik
  ```

## Build and deploy (without losing data)
- Build a single service (run where `docker-compose.yml` lives):
  ```bash
  docker compose build --no-cache <service>
  ```

- Recreate a service without touching its dependencies:
  ```bash
  docker compose up -d --no-deps --force-recreate <service>
  ```
  Note: volumes remain mounted by default — data in named volumes is preserved.

- Build and start everything:
  ```bash
  docker compose up -d --build
  ```

- Soft rebuild pattern (do not stop databases):
  ```bash
  docker compose build --no-cache service-a service-b
  docker compose up -d --no-deps --force-recreate service-a service-b
  ```

## Removing / pruning safely
- Remove a container (do not remove volumes):
  ```bash
  docker rm <container>
  docker rm -f <container>    # force remove
  ```

- Remove an image:
  ```bash
  docker rmi <image>
  ```

- Clean unused resources (be careful):
  ```bash
  docker system prune         # removes stopped containers, unused networks, dangling images
  docker system prune -a      # removes unused images too
  ```

- Remove unused volumes:
  ```bash
  docker volume prune
  ```

## Inspect and information
- Inspect container details:
  ```bash
  docker inspect <container>
  ```

- Get container IP in the `proxy` network:
  ```bash
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>
  ```

- Disk usage by Docker:
  ```bash
  docker system df
  ```

## Compose patterns you will use often
- Stop and remove containers (without removing volumes):
  ```bash
  docker compose down
  # 'down' does not remove named volumes unless you add --volumes
  docker compose down --volumes   # removes volumes (CAUTION)
  ```

- Recreate a single service:
  ```bash
  docker compose up -d --no-deps --force-recreate <service>
  ```

- Typical rebuild & restart workflow:
  ```bash
  docker compose build --no-cache <service>
  docker compose up -d --no-deps --force-recreate <service>
  ```

## Network / ports debugging
- Show which ports containers expose:
  ```bash
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
  ```

- Test connection from a container to the host (host.docker.internal):
  ```bash
  docker run --rm --network proxy --add-host host.docker.internal:host-gateway curlimages/curl:latest -v http://host.docker.internal:5175/
  ```

## Handy tips / aliases
- Use `docker compose exec <service> sh` when working inside a compose project rather than `docker exec`.
- Check files inside a container:
  ```bash
  docker exec -it <container> ls -la /usr/share/nginx/html
  docker exec -it <container> cat /etc/nginx/django.conf
  ```
- Named volumes keep data across container recreation — avoid `down --volumes` if you want to preserve DBs or uploads.

## Quick debugging patterns
- 502 Bad Gateway:
  - check `docker logs <backend>` and `docker logs <proxy (traefik)>`
  - test backend directly: `docker run --rm --network proxy curlimages/curl:latest http://<backend>:<port>/health`
- 404 from Nginx:
  - check `ls -la` inside the container and run `nginx -t`
- Old image after `compose up`:
  - run `docker compose build --no-cache <service>` and `docker compose up -d --no-deps --force-recreate <service>`

---

If you want, I can also:
- add this file to a commit and push it to your branch,
- create a small `scripts/` folder with helper scripts for rebuilds,
- provide a handful of shell aliases for frequent tasks.

Which of these would you like me to do next?
