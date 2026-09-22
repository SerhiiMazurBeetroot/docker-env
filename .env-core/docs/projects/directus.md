# Directus

Directus CMS with PostgreSQL behind Nginx. Disk path: `directus/{DOMAIN_FULL}/`.

## Create

CLI: **2 New project → Directus**.

1. Short name
2. Host (default `dev.{name}.local`)
3. Database name (default `directus`) and Directus version
4. Confirm with `y`

Nginx must be running.

## URLs

| What | Example |
| --- | --- |
| Directus | `https://dev.cms.local` |
| pgAdmin | `https://dev.cms.local.pgadmin` |

Add both names to [hosts](../system.md#hosts-file) (the CLI does this on macOS/Linux).

Containers: `{shortname}-directus`, `{shortname}-postgres`.

First-login admin is whatever the Directus image bootstrap uses in that project’s `.env` — check `directus/{DOMAIN_FULL}/` after create.

[Getting started](../getting-started.md)
