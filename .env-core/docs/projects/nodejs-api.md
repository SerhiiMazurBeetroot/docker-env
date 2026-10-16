# Node.js API

Express API behind Nginx. Shown in **New project** only when `ENV_MODE=development`. Disk path: `nodejs_api/{DOMAIN_FULL}/`.

## Create

CLI: **2 New project → Node.js API**.

1. Short name
2. Host (default `dev.{name}.local`)
3. Node version
4. Confirm with `y`

Nginx must be running. Create clones `docker-env-template-nodejs_api` from GitHub and builds the image. Set `CREATE_TEMPLATE_SOURCE=local` to copy the local template instead. The app listens on port 3000 inside the container. The host port is the one stored for the site.

## URLs

| What | Example |
| --- | --- |
| API | `https://dev.app.local` |
| Health | `https://dev.app.local/health` |

`GET /` and `GET /health` return JSON with `"ok": true`.

Container: `{shortname}-nodejs_api`.

[Getting started](../getting-started.md)
