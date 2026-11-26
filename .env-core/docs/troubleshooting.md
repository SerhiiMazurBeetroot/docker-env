# Troubleshooting

## `docker-env` not found

The alias is added on first `./setup.sh`. Restart the terminal, or:

```bash
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
```

Or run `./setup.sh` from the clone. The alias is `docker-env`; `DOCKER_ENV_DIR` must point at that clone.

## Docker / jq / Node missing

The CLI exits if `docker`, `jq`, or `node` is not on `PATH`. Install them on the host, then open a new terminal.

## Please install docker compose V2

You are on Compose v1. The CLI still falls back to `docker-compose`, but that path is not tested. Install the Compose **plugin** so `docker compose version` works.

- [Docker Compose install](https://docs.docker.com/compose/install/)

## Nginx container not running

Create and Docker actions require `nginx-proxy`. Start it with **System → Nginx proxy → Start**.

## Port already allocated

| Port | Who |
| --- | --- |
| 443 | nginx-proxy HTTPS |
| 8080 | nginx-proxy HTTP |
| 7007 | Dozzle |
| 7777 | Web UI |

Stop the other process, or change that tool’s port. docker-env expects these defaults.

To see who holds a port, and stop it:

```bash
docker-env port list
docker-env port kill 3001
```

`docker-env port kill` with no port shows a picker for ports 3000–3999 (dev servers). The same tools are in **4 Helpers → 6 Ports**. Needs `lsof`.

## Browser says the certificate is invalid

The site cert is fine only after the **root CA** is trusted. See [Trust the local CA](system.md#trust-the-local-ca). Restart the browser. After Nginx **Reset SSL**, install the new root.

## Site does not resolve

`DOMAIN_FULL` must be in the hosts file. macOS/Linux: re-run create or add the line with sudo. Windows: edit `C:\Windows\System32\drivers\etc\hosts`. Include extras (`phpmyadmin`, `mail`, …) from the CLI success message.

## Web UI will not start

1. Confirm Nginx is up (`docker ps` → `nginx-proxy`).
2. **System → Web UI → Start**.
3. Open [http://127.0.0.1:7777](http://127.0.0.1:7777), not a `*.local` host.
4. If port 7777 is taken, stop the other listener.

## Web UI login fails

Show the token with **System → Web UI → Sign-in token** and paste that value with no extra spaces. Restart the Web UI after the token changes so `nginx-webui` reloads `.env-core/system/nginx/.env`.

Stopping the Web UI does not stop Nginx. Stopping Nginx (**System → Nginx proxy → Stop**) also stops the Web UI, because both are in the same Compose stack.

## Web UI is slow on the first load

If **System → Web UI** shows `(dev)`, the UI runs `next dev`. That mode compiles each page the first time you open it, which can add 5–10 seconds after a start. Later loads are fast.

If you are not changing the Web UI code, switch to the production image with **System → Web UI → Rebuild image**. That menu item shows only in [development mode](getting-started.md#development-mode).

## Project already exists

The short domain is unique. Pick another name, or delete the old site (**3 Sites → pick the site → More → 6 Remove site**, or Delete in the Web UI).

## Helpers that destroy Docker data

**4 Helpers → 1 Docker** can stop all containers or prune volumes/images. That is machine-wide, not only docker-env. Do not use it to “fix one site”.
