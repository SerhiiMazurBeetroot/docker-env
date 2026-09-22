# Next.js

Two install modes. Disk path: `nextjs/{DOMAIN_FULL}/`.

![Create Next.js](../../.env-core/docs/gifs/nextjs.gif)

## Create

CLI: **2 New project → Next.js**, then:

| Key | Mode |
| --- | --- |
| 1 Docker | App in Compose, routed through Nginx |
| 2 Local | `create-next-app` on the host (still recorded in `instances.log`) |

Web UI create uses the Docker path.

Nginx is required for Docker mode. Local mode needs Node on the host.

You choose Next.js and Node versions (Enter accepts the listed defaults). Confirm with `y`.

Docker create runs `npm i` in the project folder after containers are up.

## URLs

| What | Example |
| --- | --- |
| Site | `https://dev.app.local` |

Container: `{shortname}-nextjs`.

[Getting started](../getting-started.md)
