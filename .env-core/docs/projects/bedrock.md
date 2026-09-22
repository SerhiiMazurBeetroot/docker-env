# Bedrock

[Roots Bedrock](https://roots.io/bedrock/) WordPress in Docker. Disk path: `bedrock/{DOMAIN_FULL}/`.

![Create Bedrock](../../.env-core/docs/gifs/bedrock.gif)

## Create

CLI: **2 New project → BEDROCK**. Same **default / custom / beetroot** flow as [WordPress](wordpress.md).

Nginx must be running. Confirm the summary, then optional Git clone.

## URLs

Admin is under `/wp/`, not `/wp-admin` on the site root.

| What | Example |
| --- | --- |
| Site | `https://dev.bedrock.local` |
| wp-admin | `https://dev.bedrock.local/wp/wp-admin` |
| phpMyAdmin | `https://dev.bedrock.local.phpmyadmin` |
| Mail | `https://dev.bedrock.local.mail` |

Default admin: `developer` / `1` unless you set custom values.

## Layout

- `docker/` — Compose
- `app/web/app` — Bedrock web root (`wp-content` equivalent)

App container: `{shortname}-bedrock`.

Composer and WP tools: **3 → 5 Tools** (same menus as WordPress).

[Getting started](../getting-started.md) · [WordPress](wordpress.md)
