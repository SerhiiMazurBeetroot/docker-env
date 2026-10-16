# Getting started

Install Docker, clone this repo, start Nginx, then create a project. After that you can use `docker-env` from any directory or the [Web UI](web-ui.md).

## Requirements

Install these on the host (not inside a container):

1. [Docker Engine](https://docs.docker.com/engine/install/) **20.10+** with **Compose v2** (`docker compose`). Docker Desktop includes Compose v2.
2. [jq](https://jqlang.github.io/jq/download/)
3. [Node.js](https://nodejs.org/) (needed to run the CLI healthcheck)

Linux: install the Compose plugin if `docker compose version` fails. Compose v1 (`docker-compose`) is no longer supported.

## Install

From the repository root:

```bash
./setup.sh
```

The first run adds a `docker-env` alias and `DOCKER_ENV_DIR` to your shell rc file (`.zshrc`, `.bashrc`, or `.profile`). Restart the terminal, or `source` that file.

Then, from any directory:

```bash
docker-env
```

Same as `./setup.sh` from the repo.

![First setup](gifs/setup.gif)

## Start Nginx

Projects need the shared proxy. In the CLI:

1. **1 — System**
2. **1 — Nginx**
3. **1 — Setup**

That creates the `dockerwp` network and `ssl-certs` volume, then starts `nginx-proxy`, `nginx-mkcert`, and `nginx-dozzle`. It also tries to start the Web UI at [http://127.0.0.1:7777](http://127.0.0.1:7777).

The first time the Web UI starts, the CLI creates a sign-in token. Show it with **1 System → 2 Web UI → 4 Show sign-in token**, then paste it on `/login`. See [Web UI](web-ui.md).

![Nginx setup](gifs/nginx.gif)

Trust the local CA once: [System: certificates](system.md#trust-the-local-ca).

## Create a project

1. **2 — New site**
2. Pick a type (see [projects](README.md#projects))
3. Enter a short domain name (example: `blog`)
4. Confirm `DOMAIN_FULL` (default is usually `dev.blog.local`)
5. Confirm the summary with `y`

On macOS and Linux the CLI appends `127.0.0.1` lines to `/etc/hosts` (sudo). On Windows, add the printed lines yourself: [hosts](system.md#hosts-file).

Open `https://dev.blog.local` (HTTPS on port **443**).

![CLI overview](gifs/docker-env.gif)

## Everyday commands

| Goal | CLI | Web UI |
| --- | --- | --- |
| Start or stop a site | **3 Sites** → pick the site | Card actions |
| Restart or rebuild | Site → **More** | Card actions |
| Import / export / search-replace DB | Site → **Database** | — |
| Shell in the app container | Site → **Shell** | — |
| Zip a site | Site → **More → Archive** | — |
| Restore a zip | **3 Sites → [r]** when an archive exists | — |
| Container logs | Dozzle | Card → logs |

Dozzle: [http://127.0.0.1:7007](http://127.0.0.1:7007)

## What you should see

```mermaid
flowchart LR
  browser[Browser]
  proxy[nginx-proxy :443]
  mkcert[mkcert]
  dozzle[Dozzle :7007]
  webui[Web UI :7777]
  site[Project containers]

  browser --> proxy
  browser --> webui
  browser --> dozzle
  mkcert --> proxy
  proxy --> site
  webui --> site
```

Next: [system services](system.md) or a [project type](README.md#projects).
