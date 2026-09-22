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

You are on Compose v1. Install the Compose **plugin** so `docker compose version` works.

- [Docker Compose install](https://docs.docker.com/compose/install/)

## Nginx container not running

Create and Docker actions require `nginx-proxy`. **1 System → 1 Nginx → 1 Setup**.

## Port already allocated

| Port | Who |
| --- | --- |
| 443 | nginx-proxy HTTPS |
| 8080 | nginx-proxy HTTP |
| 7007 | Dozzle |
| 7777 | Web UI |

Stop the other process, or change that tool’s port. docker-env expects these defaults.

## Browser says the certificate is invalid

The site cert is fine only after the **root CA** is trusted. See [Trust the local CA](system.md#trust-the-local-ca). Restart the browser. After Nginx **Re-Setup**, install the new root.

## Site does not resolve

`DOMAIN_FULL` must be in the hosts file. macOS/Linux: re-run create or add the line with sudo. Windows: edit `C:\Windows\System32\drivers\etc\hosts`. Include extras (`phpmyadmin`, `mail`, …) from the CLI success message.

## Web UI will not start

1. Confirm Nginx is up (`docker ps` → `nginx-proxy`).
2. **1 System → 3 Web UI → 1 Start**.
3. Open [http://127.0.0.1:7777](http://127.0.0.1:7777), not a `*.local` host.
4. If port 7777 is taken, stop the other listener.

Stopping the Web UI does not stop Nginx. Stopping Nginx (`compose down` on the system stack) does stop the Web UI if it was part of that project.

## Project already exists

The short domain is unique. Pick another name, or delete the old site (**3 → 1 Docker → 1 Permanently Remove**, or Delete in the Web UI).

## Helpers that destroy Docker data

**4 Helpers → 1 Docker** can stop all containers or prune volumes/images. That is machine-wide, not only docker-env. Do not use it to “fix one site”.
