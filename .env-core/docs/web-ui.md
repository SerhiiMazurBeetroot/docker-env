# Web UI

The dashboard lists sites from `.env-core/data/instances.json` and runs the same start / stop / rebuild / create / delete scripts as the CLI.

URL: [http://127.0.0.1:7777](http://127.0.0.1:7777) (localhost only, port **7777**).

## Sign in

The dashboard asks for a token on `/login`.

1. In the CLI, open **1 System → 2 Web UI → 4 Show sign-in token**
2. Copy the `WEBUI_TOKEN` value
3. Paste it on the login page

The token is created the first time that menu item runs, or the first time the Web UI starts. It is also written into `.env-core/system/nginx/.env` so the container can read it. Sign out from **Settings**.

If the login page rejects a token you just copied, restart the Web UI (**1 System → 2 Web UI → Stop**, then **Start**) so the container picks up the new value.

## Start and stop

Nginx Setup already tries to start the UI. To control it from the CLI:

1. **1 — System**
2. **2 — Web UI**
3. **1 Start**, **2 Stop**, **3 Open in browser**, or **4 Show sign-in token**

Start will start the Nginx stack first if `nginx-proxy` is down.

Stop only stops the `nginx-webui` container. Nginx, mkcert, and Dozzle keep running.

If Start says the UI is already running, use the printed URL. Do not treat “already running” as a failure.

## What it can do

- Filter and search projects (saved in the browser)
- Start, restart, rebuild, stop, delete a project
- Expand services, copy URLs (does not auto-open tabs)
- Toggle extra `/etc/hosts` names when the container can write the hosts file
- Open container logs in Dozzle
- Create a new project when `ENV_MODE=development` (same types as the CLI). The Create button stays hidden otherwise. Version fields list the published releases in `.env-core/data/catalog.json`. The Web UI refreshes that file once a day. Default leaves the choice to the CLI. A version that is not in that file is rejected before Docker starts.
- Read these guides from **Documentation** in the header (`/docs`)

The Console panel streams CLI output. On a phone, close it with the **X** in the top-right of that panel. Settings → **Open on actions** controls whether Start/Stop/Rebuild (and similar) open that panel automatically. Opening a service’s logs still opens it.

## Develop image (optional)

Rebuild / Develop menu items show only when `ENV_MODE=development`. Production use: Start / Stop / Open is enough.
