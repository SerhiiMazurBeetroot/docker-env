# PHP

A PHP app container behind Nginx. No WordPress install and no phpMyAdmin host. Disk path: `php/{DOMAIN_FULL}/`.

![Create PHP](../../.env-core/docs/gifs/php.gif)

## Create

CLI: **2 New project → PHP-Server**.

1. Short name, e.g. `api`
2. Host (default `dev.api.local`)
3. PHP version (Enter for the listed default)
4. Confirm with `y`

Nginx must be running.

## URLs

| What | Example |
| --- | --- |
| Site | `https://dev.api.local` |

App files: `php/{DOMAIN_FULL}/app/`. Container: `{shortname}-php`.

[Getting started](../getting-started.md)
