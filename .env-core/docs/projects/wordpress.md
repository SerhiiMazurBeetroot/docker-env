# WordPress

Classic WordPress in Docker behind [Nginx](../system.md). Disk path: `wordpress/{DOMAIN_FULL}/`.

![Create WordPress](../../.env-core/docs/gifs/wordpress.gif)

## Create

CLI: **2 New project → Wordpress**. Web UI: **New project**, type WordPress.

Nginx must already be running.

Setup types:

| Key | Meaning |
| --- | --- |
| 1 default | Domain + host, rest of the values are filled for you |
| 2 custom | You set DB name, table prefix, WP version, user, password, empty content, multisite, PHP |
| 3 beetroot | Agency preset; default host is `{name}.local` instead of `dev.{name}.local` |

Prompts:

1. Short name, e.g. `blog` → default host `dev.blog.local`
2. Confirm the summary (`y`)
3. Optional clone of a Git repo or theme after install

Custom defaults if you press Enter: database `db`, prefix `wp_`, user `developer`, password `1`, latest WP, PHP from the list, not empty, single site.

After create, macOS/Linux hosts are updated. [Windows hosts](../system.md#hosts-file).

## URLs

Replace the host with yours:

| What | URL |
| --- | --- |
| Site | `https://dev.blog.local` |
| wp-admin | `https://dev.blog.local/wp-admin` |
| phpMyAdmin | `https://dev.blog.local.phpmyadmin` |
| Mail | `https://dev.blog.local.mail` |

Default admin: user `developer`, password `1` (unless you changed them on custom).

## Layout

- `wp-docker/` — Compose
- `wp-content/` — themes, plugins, uploads
- `wp-database/` — SQL dumps

App container: `{shortname}-wordpress`.

## After install

- **3 → 1 Docker** — start, stop, restart, rebuild, URLs, delete
- **3 → 2 Database** — import, export, search-replace
- **3 → 5 Tools → 4 Other Services → 1 WP Workflow** — Composer, empty content, convert to multisite

[Getting started](../getting-started.md) · [Bedrock](bedrock.md)
