# Laravel

Laravel with MariaDB, phpMyAdmin, and Mailhog behind Nginx. Shown in **New site** only when `ENV_MODE=development`. Disk path: `laravel/{DOMAIN_FULL}/`.

## Create

CLI: **2 New site → Laravel**.

1. Short name
2. Host (default `dev.{name}.local`)
3. PHP version, Laravel version, and database name
4. Confirm with `y`

Nginx must be running. Create runs `composer create-project laravel/laravel` into `src/` after the containers start, installs Laravel Breeze (Blade) so `/login` exists, points Laravel at MariaDB, and runs migrations.

## URLs

| What | Example |
| --- | --- |
| Site | `https://dev.app.local` |
| Login | `https://dev.app.local/login` |
| phpMyAdmin | `https://dev.app.local.phpmyadmin` |
| Mailhog | `https://dev.app.local.mail` |

Containers: `{shortname}-laravel`, `{shortname}-mysql`, `{shortname}-phpmyadmin`, `{shortname}-mail`.

App code lives in `laravel/{DOMAIN_FULL}/src`. Database user is `root`, password `PassWorD123`, database name is the one chosen at create (default `db`).

The `/login` form asks for an email. The account created with the site is `developer@example.com` / `developer`. The same values are in `docker/.env` and `src/.env` as `LOGIN_EMAIL` and `LOGIN_PASSWORD`.

CLI: **3 Sites → pick the site → Laravel** runs Artisan and Composer (`migrate`, `migrate:fresh`, `optimize:clear`, `storage:link`, a custom Artisan command, or `composer require`). Restart, git, archive, and remove are under **More**.

[Getting started](../getting-started.md)
