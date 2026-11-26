<p align="center">
  <img alt="docker-env" src="./.env-core/docs/images/docker-env.webp" width="50%">
</p>

<p align="center">
  <a href="https://github.com/SerhiiMazurBeetroot/devENV/releases">
    <img alt="Latest release" src="https://img.shields.io/github/v/release/SerhiiMazurBeetroot/devENV?color=%23FDD835&label=release&style=for-the-badge">
  </a>
</p>

# docker-env

Run local WordPress, PHP, Next.js and other sites in Docker, each on its own HTTPS domain such as `https://dev.blog.local`.

You answer a few questions in a terminal menu (or click **New site** in the browser dashboard) and docker-env sets up the containers, the database, the SSL certificate and the hosts entry for you.

<p align="center">
  <img alt="Docker" src="https://img.shields.io/badge/docker-2496ED?style=for-the-badge&logo=docker&logoColor=white">
  <img alt="nginx-proxy" src="https://img.shields.io/badge/nginx--proxy-009639?style=for-the-badge&logo=nginx&logoColor=white">
  <img alt="mkcert" src="https://img.shields.io/badge/mkcert-F46D01?style=for-the-badge&logo=letsencrypt&logoColor=white">
  <img alt="Dozzle" src="https://img.shields.io/badge/dozzle-478061?style=for-the-badge&logo=docker&logoColor=white">
</p>

### Works on

<p align="center">
  <img alt="Linux" src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black">
  <img alt="macOS" src="https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=apple&logoColor=F0F0F0">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white">
</p>

### Creates

<p align="center">
  <img alt="WordPress" src="https://img.shields.io/badge/wordpress-21759B?style=for-the-badge&logo=wordpress&logoColor=white">
  <img alt="Bedrock" src="https://img.shields.io/badge/bedrock-525DDC?style=for-the-badge&logo=roots&logoColor=white">
  <img alt="PHP" src="https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white">
  <img alt="Next.js" src="https://img.shields.io/badge/next.js-white?style=for-the-badge&logo=nextdotjs&logoColor=black">
  <img alt="Directus" src="https://img.shields.io/badge/directus-6644FF?style=for-the-badge&logo=directus&logoColor=white">
  <img alt="Elastic Stack" src="https://img.shields.io/badge/elastic%20stack-005571?style=for-the-badge&logo=elasticsearch&logoColor=white">
</p>

## What you get

- **One proxy for every site.** A shared Nginx reverse proxy routes each domain to its project, so sites never fight over ports.
- **Trusted HTTPS.** mkcert issues local certificates. Trust the local CA once and the browser shows no warnings.
- **Ready-made stacks.** Database, admin tool and mail catcher come set up with each project.
- **Two ways to work.** A terminal menu (`docker-env`) and a browser dashboard at [http://127.0.0.1:7777](http://127.0.0.1:7777). Both run the same scripts.
- **Logs in the browser.** Dozzle at [http://127.0.0.1:7007](http://127.0.0.1:7007) shows live logs for every container.

## Requirements

Install these on your computer (not inside a container):

| Tool | Version | Notes |
| --- | --- | --- |
| [![Docker](https://img.shields.io/badge/docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docs.docker.com/engine/install/) | 20.10+ with Compose v2 | Docker Desktop includes Compose v2. On Linux, install the Compose plugin if `docker compose version` fails. |
| [![jq](https://img.shields.io/badge/jq-5A5A5A?style=flat-square&logo=json&logoColor=white)](https://jqlang.github.io/jq/download/) | any | Reads the project list and settings. |
| [![Node.js](https://img.shields.io/badge/node.js-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org/) | any current LTS | Runs the CLI health check. |

## Quick start

**1. Install.** From the repository folder, run:

```bash
./setup.sh
```

This adds a `docker-env` command to your shell. Restart the terminal, then you can run it from any folder:

```bash
docker-env
```

<img alt="First setup" src="./.env-core/docs/gifs/setup.gif?raw=true">

**2. Start the proxy.** In the menu choose **System → Nginx proxy → Start**. This starts Nginx, mkcert, Dozzle and the Web UI. Every site runs behind this proxy, so it must be running before you create or open a site.

**3. Trust the certificate.** Follow [Trust the local CA](./.env-core/docs/system.md#trust-the-local-ca) once so browsers accept your local HTTPS sites.

**4. Create a site.** Choose **2 New site**, pick a type, and enter a short name such as `blog`. When it finishes, open `https://dev.blog.local`.

On macOS and Linux the hosts file is updated for you (you may be asked for your password). On Windows, add the lines the CLI prints to your [hosts file](./.env-core/docs/system.md#hosts-file).

You can also skip the menu:

```bash
docker-env create --type wordpress --name blog
```

More detail: [Getting started](./.env-core/docs/getting-started.md).

## Project types

| Type | What's included | Guide |
| --- | --- | --- |
| ![WordPress](https://img.shields.io/badge/wordpress-21759B?style=for-the-badge&logo=wordpress&logoColor=white) | ![PHP](https://img.shields.io/badge/PHP-777BB4?style=flat-square&logo=php&logoColor=white) ![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white) ![phpMyAdmin](https://img.shields.io/badge/phpMyAdmin-6C78AF?style=flat-square&logo=phpmyadmin&logoColor=white) ![Mailhog](https://img.shields.io/badge/Mailhog-D14836?style=flat-square&logo=gmail&logoColor=white) ![Composer](https://img.shields.io/badge/Composer-885630?style=flat-square&logo=composer&logoColor=white) ![Multisite](https://img.shields.io/badge/multisite-18BFFF?style=flat-square&logo=wordpress&logoColor=white) | [wordpress.md](./.env-core/docs/projects/wordpress.md) |
| ![Bedrock](https://img.shields.io/badge/bedrock-525DDC?style=for-the-badge&logo=roots&logoColor=white) | ![PHP](https://img.shields.io/badge/PHP-777BB4?style=flat-square&logo=php&logoColor=white) ![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white) ![phpMyAdmin](https://img.shields.io/badge/phpMyAdmin-6C78AF?style=flat-square&logo=phpmyadmin&logoColor=white) ![Mailhog](https://img.shields.io/badge/Mailhog-D14836?style=flat-square&logo=gmail&logoColor=white) ![Composer](https://img.shields.io/badge/Composer-885630?style=flat-square&logo=composer&logoColor=white) | [bedrock.md](./.env-core/docs/projects/bedrock.md) |
| ![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white) | ![PHP](https://img.shields.io/badge/PHP-777BB4?style=flat-square&logo=php&logoColor=white) plain app container | [php.md](./.env-core/docs/projects/php.md) |
| ![Next.js](https://img.shields.io/badge/next.js-white?style=for-the-badge&logo=nextdotjs&logoColor=black) | ![Node.js](https://img.shields.io/badge/node.js-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white) ![Next.js](https://img.shields.io/badge/next.js-black?style=flat-square&logo=nextdotjs&logoColor=white) in Docker or from a local folder | [nextjs.md](./.env-core/docs/projects/nextjs.md) |
| ![Directus](https://img.shields.io/badge/directus-6644FF?style=for-the-badge&logo=directus&logoColor=white) | ![Directus](https://img.shields.io/badge/directus-6644FF?style=flat-square&logo=directus&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![pgAdmin](https://img.shields.io/badge/pgAdmin-593D88?style=flat-square&logo=postgresql&logoColor=white) | [directus.md](./.env-core/docs/projects/directus.md) |
| ![Elastic Stack](https://img.shields.io/badge/elastic%20stack-005571?style=for-the-badge&logo=elasticsearch&logoColor=white) | ![Elasticsearch](https://img.shields.io/badge/Elasticsearch-005571?style=flat-square&logo=elasticsearch&logoColor=white) ![Kibana](https://img.shields.io/badge/Kibana-E8478B?style=flat-square&logo=kibana&logoColor=white) ![Logstash](https://img.shields.io/badge/Logstash-FEC514?style=flat-square&logo=logstash&logoColor=black) | [elasticsearch.md](./.env-core/docs/projects/elasticsearch.md) |

Every site gets its own URLs for its tools, for example:

| What | URL |
| --- | --- |
| Site | `https://dev.blog.local` |
| phpMyAdmin | `https://dev.blog.local.phpmyadmin` |
| Mail (Mailhog) | `https://dev.blog.local.mail` |

## Shared services

These run once and serve every project.

| Service | Address | What it does |
| --- | --- | --- |
| [![nginx-proxy](https://img.shields.io/badge/nginx--proxy-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://hub.docker.com/r/nginxproxy/nginx-proxy) | ports 443 and 8080 | Routes each domain to the right project |
| [![mkcert](https://img.shields.io/badge/mkcert-F46D01?style=for-the-badge&logo=letsencrypt&logoColor=white)](https://github.com/aegypius/mkcert-for-nginx-proxy) | — | Creates and renews local SSL certificates |
| [![Dozzle](https://img.shields.io/badge/dozzle-478061?style=for-the-badge&logo=docker&logoColor=white)](https://dozzle.dev/) | [127.0.0.1:7007](http://127.0.0.1:7007) | Live container logs in the browser |
| ![Web UI](https://img.shields.io/badge/web%20ui-111111?style=for-the-badge&logo=nextdotjs&logoColor=white) | [127.0.0.1:7777](http://127.0.0.1:7777) | Dashboard to create, start, stop, rebuild and delete sites |

The Web UI asks for a sign-in token. Get it from **System → Web UI → Sign-in token**. See [Web UI](./.env-core/docs/web-ui.md).

<p align="center">
  <a href="./.env-core/docs/images/webui.png"><img alt="docker-env Web UI: the Sites dashboard with running sites, CPU and memory, type filters and a New site button" src="./.env-core/docs/images/webui.png" width="100%"></a>
</p>


## Walkthroughs

<details>
  <summary><b>The main menu</b></summary>
  <img alt="docker-env menu" src="./.env-core/docs/gifs/docker-env.gif?raw=true">
</details>

<details>
  <summary><b>Start the Nginx proxy</b></summary>
  <img alt="Nginx setup" src="./.env-core/docs/gifs/nginx.gif?raw=true">
</details>

<details>
  <summary><b>Create a WordPress site</b></summary>
  <img alt="Create WordPress" src="./.env-core/docs/gifs/wordpress.gif?raw=true">
</details>

<details>
  <summary><b>Create a Bedrock site</b></summary>
  <img alt="Create Bedrock" src="./.env-core/docs/gifs/bedrock.gif?raw=true">
</details>

<details>
  <summary><b>Create a PHP site</b></summary>
  <img alt="Create PHP" src="./.env-core/docs/gifs/php.gif?raw=true">
</details>

<details>
  <summary><b>Create a Next.js site</b></summary>
  <img alt="Create Next.js" src="./.env-core/docs/gifs/nextjs.gif?raw=true">
</details>

## Documentation

| Page | Open it when you want to |
| --- | --- |
| [Getting started](./.env-core/docs/getting-started.md) | Install, start Nginx, create your first site, everyday commands |
| [Web UI](./.env-core/docs/web-ui.md) | Use the browser dashboard |
| [System services](./.env-core/docs/system.md) | Understand the proxy, certificates, hosts file, logs and mail |
| [Troubleshooting](./.env-core/docs/troubleshooting.md) | Fix busy ports, certificate warnings, hosts or login problems |

## Credits

Built on [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), [mkcert-for-nginx-proxy](https://github.com/aegypius/mkcert-for-nginx-proxy) and [Dozzle](https://dozzle.dev/). See also [Docker best practices](https://docs.docker.com/build/building/best-practices/).
