<p align="center">
  <img alt="devENV" src="./env-core/docs/images/featured.png" height="100%" width="40%">
</p>

# Local Docker Wordpress CLI Development Environment
This environment was created to automate your local WordPress development.
<br>
Spin up a local environment on Linux, Mac, and Windows using CLI.

<br>

# 1. What's inside the containers
<p align="left">
  <a href="https://hub.docker.com/_/php">
    <img alt="PHP" src="https://img.shields.io/badge/PHP%20fpm-option-8892bf">
  </a>

  <a href="https://hub.docker.com/_/mariadb">
    <img alt="MariaDB" src="https://img.shields.io/badge/MariaDB-latest-c0765a">
  </a>

  <a href="https://hub.docker.com/_/wordpress">
    <img alt="WordPress" src="https://img.shields.io/badge/WordPress-option-lightgrey">
  </a>

  <a href="https://hub.docker.com/r/jwilder/nginx-proxy">
    <img alt="Proxy" src="https://img.shields.io/badge/jwilder-latest-00a652">
  </a>

  <a href="https://hub.docker.com/_/adminer">
    <img alt="Adminer" src="https://img.shields.io/badge/Adminer-v4.8.1-f99d0f">
  </a>

  <a href="https://github.com/aegypius/mkcert-for-nginx-proxy">
    <img alt="Mkcert" src="https://img.shields.io/badge/mkcert-v1.0.2-f99d0f">
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
| Projects      | Auto-creat all instances for wp site                |
| PHP           | Choose from active PHP version                      |
| Wordpress     | Install the version you need or use the latest      |
| Database      | Database import and export, search-replace          |
| Composer      | Install Composer inside container                   |
| Repository    | Clone an existing theme from your Repository        |
| GitHub        | Create repo and push project                        |
| GitLab        | Create repo and push project                        |

<br>

# 4. Project tree

```
├── setup.sh              # Run devENV
├── wp-instances.log      # List of installed sites
├── env-core              # devENV core files
|     └── nginx           # Nginx-proxy
|     └── sh              # Bash scripts
|     └── templates       # Global templates
└── projects              # WordPress sites go here
```

<br>

# [5. Start the application](./env-core/docs/5-doc.MD#5-start-the-application)

<br>

# [6. How to](./env-core/docs/6-doc.MD#6-how-to)

<br>

# 7. Related projects
1. [Nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)
2. [Mkcert-for-nginx-proxy](https://github.com/aegypius/mkcert-for-nginx-proxy)
