<p align="center">
  <img alt="devENV" src="./env-core/images/featured.png" height="100%" width="40%">
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

# 5. Start the application:

Run from the command line:

```
./setup.sh
```

## 5.1 First setup

First of all you need to run Nginx server [option 1]

| Step | Option | Description              |
|------|--------|--------------------------|
| 1    | 1      | Nginx                    |
| 2    | 1      | Setup Nginx server       |
| 3    | 0      | Return to main menu      |

<br>

## 5.2 Create new project [default]

| Step | Option  | Description               | Example        |   |
|------|---------|---------------------------|----------------|---|
| 1    | 2       | New project               |                |   |
| 2    | 1       | default                   |                |   |
| 3    |         | Enter Domain Name         | test           |   |
| 4    |         | Enter DOMAIN_FULL         | dev.test.local | * |
| 5    | [Y/n]   | Is correct?               |                |   |
| 6    | [Y/n]   | Remove default content?   |                |   |
| 7    | [Y/n]   | Clone project?            |                |   |
| 8    |         | Windows: Add to host file |                |   |

*Variables has default value.

<br>

## 5.3 Create new project [custom]

| Step | Option  | Description               | Example        |   |
|------|---------|---------------------------|----------------|---|
| 1    | 2       | New project               |                |   |
| 2    | 2       | custom                    |                |   |
| 3    |         | Enter Domain Name         | test           |   |
| 4    |         | Enter DOMAIN_FULL         | dev.test.local | * |
| 5    |         | Enter DB_NAME             | db             | * |
| 6    |         | Enter TABLE_PREFIX        | wp_            | * |
| 7    |         | Enter WP_VERSION          | 5.8.3          | * |
| 8    |         | Enter WP_USER             | developer      | * |
| 9    |         | Enter WP_PASSWORD         | 1              | * |
| 10   |         | Enter PHP_VERSION         | 8.0            | * |
| 11   | [Y/n]   | Install Composer ?        | no             | * | 
| 12   | [Y/n]   | Is correct?               |                |   |
| 13   | [Y/n]   | Remove default content?   |                |   |
| 14   | [Y/n]   | Clone project?            |                |   |
| 15   |         | Windows: Add to host file |                |   |

*Variables has default value.

<br>

## 5.4 Create new project [beetroot]

| Step | Option  | Description               | Example        |   |
|------|---------|---------------------------|----------------|---|
| 1    | 2       | New project               |                |   |
| 2    | 3       | beetroot                  |                |   |
| 3    |         | Enter Domain Name         | test           |   |
| 4    | 1       | type? [default] [custom]  |                |   |
| 5    |         | Enter DOMAIN_FULL         | dev.test.local | * |
| 6    | [Y/n]   | Is correct?               |                |   |
| 7    | [Y/n]   | Remove default content?   |                |   |
| 8    | [Y/n]   | Clone project?            |                |   |
| 9    |         | Repo url                  |                |   |
| 10   |         | Windows: Add to host file |                |   |

*Variables has default value.

<br>

## 5.5 Environment options:

```
1 - Nginx

    1 - Setup Nginx container first time

    2 - Stop container

    3 - Start container

    4 - Restart container

    5 - Rebuild Nginx container

2 - New project

    1 - default

    2 - custom

    3 - beetroot

3 - Existing project

    1 - Docker actions

        1 - Permanently remove project

        2 - Stop container

        3 - Start container

        4 - Restart container

        5 - Rebuild container

        6 - Fix permissions

        7 - Run composer.json

        8 - Install composer package

    2 - Database actions

        1 - Update DB (import from backup file)

        2 - Dump DB (export to backup file)

        3 - Search-Replace

        4 - Replace project from DB

    3 - GIT actions

        1 - Clone from repo

        2 - Create GitHUB repo

        3 - Create GitLAB repo

    4 - List of exisiting projects

4 - ENV settings

    1 - ENV_UPDATES

    2 - ENV_THEME

```

<br>

# 6. How to:

## 6.1 Install trusted certificates


```
Certificates will be automatically created for all running instances.

You need one time manually add root certs:
```


| Step | Action                | Description                               |
|------|-----------------------|-------------------------------------------|
| 1    | Open directory        | env-core/nginx/certs-root/                |
| 2    | Rename file           | rootCA.pem => rootCA.crt                  |
| 3    | Open certificate      | rootCA.crt                                |
| 4    | Install certificate   | [screen 1](./env-core/images/certs-1.jpg) |
| 5    | Choose store location | [screen 2](./env-core/images/certs-2.jpg) |
| 6    | Select store          | [screen 3](./env-core/images/certs-3.jpg) |
| 7    | Import certificate    | [screen 4](./env-core/images/certs-4.jpg) |
| 8    | Confirm install       | [screen 5](./env-core/images/certs-5.jpg) |
| 9    | Restart browser       |                                           |


Tutorials how to setup:

1. [Windows:](https://docs.microsoft.com/en-us/skype-sdk/sdn/articles/installing-the-trusted-root-certificate) Installing a trusted root certificate
2. [Mac:](https://support.securly.com/hc/en-us/articles/206058318-How-to-install-the-Securly-SSL-certificate-on-Mac-OSX-) How to install the Securly SSL certificate on Mac OSX

### Don't forget to restart your browser !

If you reinstall the environment, you need to update the root certificates.


<br>

## 6.2 Add or remove a vhost

```
For Windows User

Please remember to add or remove your domain in the Windows host file:

1. Open file to edit [C:\Windows\System32\drivers\etc\hosts]

2. Add line as an example: 127.0.0.1 dev.test.local

3. Save file

```

<br>

## 6.3 Database management tool

```
In this envinronment used Adminer database management tool.

To access any database, all you need to do is visit its link through your browser.

As an example: https://dev.test.local/adminer.php
```

Tutorials:

1. [How to use Adminer](https://kinsta.com/blog/adminer/) 


<br>

## 6.4 GIT
```
An access token is used to automatically create repositories for project using the command line.
```
Tutorials:

1. [GitHub: Creating a personal access token](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) 
2. [GitLab: Creating a personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) 

<br>

# 7. Related projects
1. [Nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)
2. [Mkcert-for-nginx-proxy](https://github.com/aegypius/mkcert-for-nginx-proxy)
