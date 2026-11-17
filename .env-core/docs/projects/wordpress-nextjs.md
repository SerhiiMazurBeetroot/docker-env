# WordPress + Next.js

Next.js is the public site. WordPress is the admin at `{host}.wp`, with MariaDB, phpMyAdmin, and Mailhog. Shown in **New site** only when `ENV_MODE=development`. Disk path: `wordpress_nextjs/{DOMAIN_FULL}/`.

## Create

CLI: **2 New site → WordPress + Next.js**.

1. Short name
2. Host (default `dev.{name}.local`)
3. Database name, table prefix, WordPress version, user, password, empty content, multisite, PHP version, and Node version
4. Confirm with `y`

Nginx must be running. Create clones `docker-env-template-wordpress_nextjs`, starts the containers, then runs `wp core install`.

## URLs

| What | Example |
| --- | --- |
| Site | `https://dev.app.local` |
| WordPress admin | `https://dev.app.local.wp/wp-admin` |
| phpMyAdmin | `https://dev.app.local.phpmyadmin` |
| Mailhog | `https://dev.app.local.mail` |

Containers: `{shortname}-nextjs`, `{shortname}-wordpress`, `{shortname}-mysql`, `{shortname}-phpmyadmin`, `{shortname}-mail`.

The Next.js page reads `http://{shortname}-wordpress/wp-json` from inside Docker. The homepage shows the WordPress site name when that request succeeds.

Database user is `root`, password `PassWorD123`, database name is the one chosen at create (default `db`).

[Getting started](../getting-started.md)
