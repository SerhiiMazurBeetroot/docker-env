# Updates check

A developer page that compares what the repo pins with what is running and with the newest published release. Open it from **Updates** in the Web UI sidebar (`/updates`). The sidebar item and the page are available only when `ENV_MODE=development` (feature id `updates` in `sh/core/wip_features.ids`).

The check is read-only. It never edits a pin, pulls an image, or restarts a container. Each row says where the pin is and how to apply the change, and the update stays a change you make and commit.

## What it checks

| Group | Pin read from | Running | Newest from |
| --- | --- | --- | --- |
| System images (nginx, mkcert, dozzle) | `image:` lines in `system/nginx/docker-compose.yml` | `docker inspect` of the container (version label, else the tag) | Docker Hub tags |
| Web UI Node.js | `ARG NODE_IMAGE` in `webui/Dockerfile` | `NODE_VERSION` in the `nginx-webui` container | nodejs.org release list and the Node release schedule (LTS, end of life) |
| Web UI Docker CLI | `ARG DOCKER_CLI_IMAGE` in `webui/Dockerfile` | `docker version` inside `nginx-webui` | Docker Hub tags |
| Web UI packages | `webui/package.json` ranges, versions from `package-lock.json` | the locked version | npm registry `latest` |
| docker-env | `CORE_VERSION` in `setup.sh` | the same | latest GitHub release of the `origin` remote |

**Latest in series** is the newest release inside the pin (`1.11` → newest `1.11.x`). **Newest** is the newest release overall. For Node it is the newest major that is LTS today.

## Statuses

| Status | Meaning |
| --- | --- |
| `up to date` | Nothing to do |
| `update available` | A newer patch or minor inside the pin, or a newer package or docker-env release |
| `new major` | A newer major exists. Change the pin on purpose, after reading the changelog |
| `recreate container` | The container runs a different image than the pin. **System → Nginx → Rebuild** |
| `rebuild image` | The Web UI image was built from an older pin. **System → Web UI → Rebuild image** |
| `end of life soon` / `end of life` | Node major within 90 days of, or past, its end of life |
| `not pinned` | The image uses `latest` or no tag |
| `no recent release` | The newest tag is more than two years old (mkcert) |
| `unknown` | A lookup failed, or there was nothing to compare with |

Without Docker the Running column is empty, and a series pin is not reported as out of date: the next pull already gets the newest patch.

## When it runs

- Once a day, from the same loop as the version catalog (`catalog_refresh.sh loop` in the Web UI container), only in development mode.
- **Check now** on the page (`POST /api/updates` → `webui_cli.sh updates`).
- By hand: `bash .env-core/sh/system/updates/updates_check.sh force`

The result is `.env-core/data/updates.json`. A failed lookup becomes an `errors` entry and an `unknown` row. If every lookup fails (offline), the previous file stays.

## Adding something to check

Add a function next to `updates_check_images` in `sh/system/updates/updates_check.sh` that calls `_updates_row`, and call it from `updates_check_write`. A new group also needs an entry in `GROUPS` in `webui/app/components/updates/UpdatesPage.js`. Unit tests are in `tests/unit/test_updates_check.sh`; they stub `_updates_curl` and `_updates_docker` so they run offline.
