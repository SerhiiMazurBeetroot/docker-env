# Directus

Directus CMS with PostgreSQL behind Nginx. Disk path: `directus/{DOMAIN_FULL}/`.

## Create

CLI: **2 New site → Directus**.

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

The first admin login is `ADMIN_EMAIL` / `ADMIN_PASSWORD` in `directus/{DOMAIN_FULL}/docker/.env`. Change them before you rely on the site.

[Getting started](../getting-started.md)
