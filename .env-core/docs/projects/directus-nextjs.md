# Directus + Next.js

Next.js site with Directus and PostgreSQL behind Nginx. Shown in **New project** only when `ENV_MODE=development`. Disk path: `directus_nextjs/{DOMAIN_FULL}/`.

## Create

CLI: **2 New project → Directus + Next.js**.

1. Short name
2. Host (default `dev.{name}.local`)
3. Database name (default `directus`), Directus version, and Node version
4. Confirm with `y`

Nginx must be running.

## URLs

| What | Example |
| --- | --- |
| Next.js site | `https://dev.cms.local` |
| Directus | `https://dev.cms.local.directus` |
| pgAdmin | `https://dev.cms.local.pgadmin` |

Add all three names to [hosts](../system.md#hosts-file) (the CLI does this on macOS/Linux).

Containers: `{shortname}-nextjs`, `{shortname}-directus`, `{shortname}-postgres`, `{shortname}-pgadmin`.

Directus admin login comes from the project `.env`: `admin@example.com` / `d1r3ctu5`. Change `ADMIN_EMAIL` and `ADMIN_PASSWORD` before you rely on the site.

The Next.js home page calls Directus `/server/health` on the Docker network (`DIRECTUS_INTERNAL_URL`). The browser uses `NEXT_PUBLIC_DIRECTUS_URL`.

[Getting started](../getting-started.md)
