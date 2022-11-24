<p align="center">
  <img alt="devENV" src="./.env-core/docs/images/featured-new.png" height="100%" width="50%">
</p>

<p align="center" dir="auto">
  <a href="https://github.com/SerhiiMazurBeetroot/devENV/releases">
    <img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/SerhiiMazurBeetroot/devENV">
  </a>
</p>

# Docker Local Environment

This environment was created to automate your local development.

Spin up a local environment on Linux, Mac, and Windows using CLI.

<br>

# Automatic installation for the following projects:

- Wordpress
- Bedrock
- PHP simple

<br>

# 1. What's inside the containers
<p align="left">
  <a href="https://hub.docker.com/r/jwilder/nginx-proxy">
    <img alt="Proxy" src="https://img.shields.io/badge/jwilder-latest-00a652">
  </a>
    <a href="https://github.com/aegypius/mkcert-for-nginx-proxy">
    <img alt="Mkcert" src="https://img.shields.io/badge/mkcert-v1.0.2-f99d0f">
  </a>
  <a href="https://hub.docker.com/_/php">
    <img alt="PHP" src="https://img.shields.io/badge/PHP%20fpm-option-8892bf">
  </a>
  <a href="https://hub.docker.com/_/mariadb">
    <img alt="MariaDB" src="https://img.shields.io/badge/MariaDB-latest-c0765a">
  </a>
  <a href="https://hub.docker.com/_/wordpress">
    <img alt="WordPress" src="https://img.shields.io/badge/WordPress-option-lightgrey">
  </a>
  <a href="https://hub.docker.com/_/adminer">
    <img alt="Adminer" src="https://img.shields.io/badge/Adminer-v4.8.1-f99d0f">
  </a>
  <a href="https://hub.docker.com/_/phpmyadmin">
    <img alt="phpMyAdmin" src="https://img.shields.io/badge/phpMyAdmin-latest-green">
  </a>
</p>

<br>

# 2. Requirements
 
1. Install Docker v20.10+ [Linux,](https://docs.docker.com/engine/installation) 
[Docker for Mac,](https://docs.docker.com/engine/installation/mac)
[Docker for Windows](https://docs.docker.com/engine/installation/windows)


2. For Linux additionally install [Docker Compose](https://docs.docker.com/compose/install) v1.29+

<br>

# 3. Features

| Name          | Description                                         |
|---------------|-----------------------------------------------------|
| Nginx-proxy   | Automated Nginx reverse proxy for docker containers |
| Certificates  | Automatic creation/renewal  SSL certificates        |
| Logs          | Follow log output for Nginx, WP instance            |
| PHP           | Choose from active PHP version                      |
| Wordpress     | Choose a version or use the latest                  |
| Database      | Database import and export, search-replace          |
| Composer      | Install Composer inside container                   |
| GIT           | Clone an existing theme, create repo and push       |
| Archive       | Archive an inactive project (can be restored)       |

<br>

# 4. Project tree

```
├── setup.sh              # Run devENV
├── .env-core             # devENV core files
|     └── nginx           # Nginx-proxy
|     └── sh              # Bash scripts
|     └── templates       # Global templates
|     └── instances.log   # List of installed sites
└── wordpress             # WordPress sites go here
└── bedrock               # Bedrock sites go here
└── php                   # PHP simple sites go here
```

<br>

# [5. Start the application](./.env-core/docs/5-doc.MD#51-first-setup)

## [5.1 First setup](./.env-core/docs/5-doc.MD#51-first-setup)

## [5.2 Create new project Wordpress](./.env-core/docs/5-doc-new-wordpress.MD#create-new-project)

## [5.3 Create new project Bedrock](./.env-core/docs/5-doc-new-wordpress.MD#create-new-project)

## [5.4 Create new project Simple PHP](./.env-core/docs/5-doc-new-php.MD#54-create-new-simple-php)

## [5.5 Environment options](./.env-core/docs/5-doc-environment-options.MD#55-environment-options)
<br>

# [6. How to](./.env-core/docs/6-doc.MD#6-how-to)

<br>

# 7. Related projects
1. [Nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)
2. [Mkcert-for-nginx-proxy](https://github.com/aegypius/mkcert-for-nginx-proxy)
