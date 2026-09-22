# Documentation

docker-env is a local Docker toolbox. The CLI and [Web UI](web-ui.md) wrap the same scripts. They do not reimplement Docker.

| Kind | Page | Use it when |
| --- | --- | --- |
| Tutorial | [Getting started](getting-started.md) | First install, Nginx, first site |
| How-to | [Web UI](web-ui.md) | Dashboard at `http://127.0.0.1:7777` |
| How-to | [Projects](#projects) | Create and run a stack |
| Explanation | [System services](system.md) | Nginx proxy, TLS, hosts, Dozzle, Mail |
| How-to | [Troubleshooting](troubleshooting.md) | Ports, certs, Compose v2, hosts |

[Back to README](../README.MD)

## Projects

Stable types (always in **New project**):

- [WordPress](projects/wordpress.md)
- [Bedrock](projects/bedrock.md)
- [PHP](projects/php.md)
- [Next.js](projects/nextjs.md)
- [Directus](projects/directus.md)
- [Elastic Stack](projects/elasticsearch.md)

Laravel, [Directus + Next.js](projects/directus-nextjs.md), WP + Next.js, and Node.js appear only when `ENV_MODE=development` in `.env-core/data/settings.log`.

## Main menu

```
docker-env
├── 1 System Services     Nginx, Web UI
├── 2 New project         create a site
├── 3 Project Services    Docker, database, CLI, list, tools
└── 4 Helpers             Docker prune, permissions, Git, disk
```

Projects live under `{type}/{host}/` in this repo (for example `wordpress/dev.blog.local/`).
