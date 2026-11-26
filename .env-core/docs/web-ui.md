# Web UI

The dashboard lists sites from `.env-core/data/instances.json` and runs the same start / stop / rebuild / create / delete scripts as the CLI.

URL: [http://127.0.0.1:7777](http://127.0.0.1:7777) (localhost only, port **7777**).

## Sign in

The dashboard asks for a token on `/login`.

1. In the CLI, open **System → Web UI → Sign-in token**
2. Copy the `WEBUI_TOKEN` value
3. Paste it on the login page

The token is created the first time that menu item runs, or the first time the Web UI starts. It is also written into `.env-core/system/nginx/.env` so the container can read it. Sign out from **Settings**.

With no token set, the dashboard refuses every page and API call (the API answers `503`). The Web UI container controls Docker, so it never runs open. Create the token from the menu above, then restart the Web UI.

If the login page rejects a token you just copied, restart the Web UI (**System → Web UI → Stop**, then **Start**) so the container picks up the new value.

## Start and stop

Starting Nginx already tries to start the UI. To control it from the CLI, open **System → Web UI**. The menu lists only what fits the current state:

- running: **Open in browser**, **Stop**, **Sign-in token**
- stopped: **Start**, **Sign-in token**

Start will start the Nginx stack first if `nginx-proxy` is down.

Stop only stops the `nginx-webui` container. Nginx, mkcert, and Dozzle keep running.

If Start says the UI is already running, use the printed URL. Do not treat “already running” as a failure.

## What it can do

- Filter and search projects (saved in the browser)
- Start, restart, rebuild, stop, delete a project
- Expand services, copy URLs (does not auto-open tabs)
- Toggle extra `/etc/hosts` names when the container can write the hosts file
- Open container logs in Dozzle
- Create a new project with **New site** (same types as the CLI). Work-in-progress types are listed only when `ENV_MODE=development` and are marked **dev**. Version fields list the published releases in `.env-core/data/catalog.json`. The Web UI refreshes that file once a day. Leave a field on Default to use the type’s default version. A version that is not in that file is rejected before Docker starts.
- Read these guides from **Documentation** in the header (`/docs`)

The Console panel streams CLI output. On a phone, close it with the **X** in the top-right of that panel. Settings → **Open on actions** controls whether Start/Stop/Rebuild (and similar) open that panel automatically. Opening a service’s logs still opens it.

## Develop image (optional)

**Rebuild image** and **Develop mode** show only in [development mode](getting-started.md#development-mode), marked *dev only*. For normal use, Start / Stop / Open is enough.

- **Rebuild image** builds the production image (`next start`). Pages are compiled once, during the build.
- **Develop mode** mounts `.env-core/webui` and runs `next dev`, so code edits show without a rebuild. Each page compiles the first time it is opened, so the first load after a start is slow. The Web UI menu status shows `(dev)` in this mode.
