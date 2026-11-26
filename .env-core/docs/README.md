# Documentation

docker-env runs local sites in Docker behind one Nginx proxy. The CLI and the Web UI call the same scripts.

| Page | When to open it |
| --- | --- |
| [Getting started](getting-started.md) | Install, Nginx, first site |
| [Web UI](web-ui.md) | Dashboard at `http://127.0.0.1:7777` |
| [System services](system.md) | Proxy, certificates, hosts, logs, mail |
| [Troubleshooting](troubleshooting.md) | Ports, certs, hosts, login |
| [Projects](#projects) | How a stack is created |

[Back to the project README](../../README.MD)

## Projects

Each type has its own page:

- [WordPress](projects/wordpress.md)
- [Bedrock](projects/bedrock.md)
- [PHP](projects/php.md)
- [Next.js](projects/nextjs.md)
- [Directus](projects/directus.md)
- [Elastic Stack](projects/elasticsearch.md)

## Main menu

```
docker-env
├── 1 System     Nginx, Web UI, settings
├── 2 New site   create a site
├── 3 Sites      start, shell, database, archive
└── 4 Helpers    Docker prune, permissions, Git, disk usage, Mac cleanup, ports
```

**4 Helpers → 5 Mac cleanup** deletes cache folders (browser, Homebrew, npm, Yarn and similar) in your home folder. It is not limited to docker-env.

Site files live under `{type}/{host}/` in this repo (for example `wordpress/dev.blog.local/`).
