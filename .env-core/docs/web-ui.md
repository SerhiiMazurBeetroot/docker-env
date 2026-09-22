# Web UI

The dashboard lists sites from `.env-core/data/instances.log` and runs the same start / stop / rebuild / create / delete scripts as the CLI.

URL: [http://127.0.0.1:7777](http://127.0.0.1:7777) (localhost only, port **7777**).

## Start and stop

Nginx Setup already tries to start the UI. To control it from the CLI:

1. **1 — System Services**
2. **3 — Web UI**
3. **1 Start**, **2 Stop**, or **3 Open in browser**

Start will start the Nginx stack first if `nginx-proxy` is down.

Stop only stops the `nginx-webui` container. Nginx, mkcert, and Dozzle keep running.

If Start says the UI is already running, use the printed URL. Do not treat “already running” as a failure.

## What it can do

- Filter and search projects (saved in the browser)
- Start, restart, rebuild, stop, delete a project
- Expand services, copy URLs (does not auto-open tabs)
- Toggle extra `/etc/hosts` names when the container can write the hosts file
- Open container logs in Dozzle
- Create a new project (same types as the CLI)

The Console panel streams CLI output. On a phone, close it with the **X** in the top-right of that panel.

## Develop image (optional)

Rebuild / Develop menu items show only when `ENV_MODE=development`. Production use: Start / Stop / Open is enough.
