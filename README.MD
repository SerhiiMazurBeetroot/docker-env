<p align="center">
  <img alt="devENV" src="./env-core/featured.png" height="100%" width="40%">
</p>

# Local Docker WP devENV
This environment was created to automate your local WordPress development.
<br>
Spin up a local environment on Linux, Mac, and Windows.

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
| Repository    | Clone an existing theme from your repo              |
|               |                                                     |

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

## 5.1 Run from the command line

```
./setup.sh
```

<br>

### Choose one from the following options:

```
1 - Nginx

2 - New project

3 - Existing project

4 - ENV settings
```
### First of all you need to run Nginx server [option 1]

<br>


## 5.2 With the server, you can run the following commands:



```
1 - Setup Nginx container first time

2 - Stop container

3 - Start container

4 - Restart container

5 - Rebuild Nginx container
```

<br>

## 5.3 Create new project [option 2]

All projects will be created automatically.

<br>

## You just need to choose installation type:

| #   | Type     | Description                          |
|-----|----------|--------------------------------------|
| 1   | default  | Use all default variables            |
| 2   | custom   | Fill all variables about the project |
| 3   | beetroot | Use all default variables, clone project, replace project & import DB |
|     |          |                                      |

## Prepare an answer to a couple of questions about the required project variables:


| Variables     | Example        |   |
|---------------|----------------|---|
| DOMAIN_NAME   | test           |   |
| DOMAIN_FULL   | dev.test.local | * |
| DB_NAME       | db             | * |
| TABLE_PREFIX  | wp_            | * |
| WP_VERSION    | 5.8.3          | * |
| WP_USER       | developer      | * |
| WP_PASSWORD   | 1              | * |
| PHP_VERSION   | 8.0            | * | 
|               |                |   | 

*Variables has default value.


<br>

## 5.4 Actions with existing sites [option 3]

```
1 - Permanently remove project

2 - Stop container

3 - Start container

4 - Restart container

5 - Rebuild container

6 - Docker actions

7 - Database actions

    1 - Update DB (import from backup file)

    2 - DB dump (export to backup file)

    3 - Search-Replace

8 - Fix permissions

9 - Clone from repo
```

<br>

## 5.5 Trusted certificates


```
Certificates will be automatically created for all running instances.

You need one time manually add root certs:
```


| Step | Action              | Description                |
|------|---------------------|----------------------------|
| 1    | Open directory      | env-core/nginx/certs-root/ |
| 2    | Rename file         | rootCA.pem => rootCA.crt   |
| 3    | Install certificate | rootCA.crt                 |

Tutorials how to setup:

1. [Windows:](https://docs.microsoft.com/en-us/skype-sdk/sdn/articles/installing-the-trusted-root-certificate) Installing a trusted root certificate
2. [Mac:](https://support.securly.com/hc/en-us/articles/206058318-How-to-install-the-Securly-SSL-certificate-on-Mac-OSX-) How to install the Securly SSL certificate on Mac OSX

### Don't forget to restart your browser !

If you reinstall the environment, you need to update the root certificates.


<br>

## 5.6 Add or remove a vhost

```
For Windows User

Please remember to add or remove your domain in the Windows host file:

1. Open file to edit [C:\Windows\System32\drivers\etc\hosts]

2. Add line as an example: 127.0.0.1 dev.test.local

3. Save file

```

<br>

## 5.7 Database management tool

```
In this envinronment used Adminer database management tool.

To access any database, all you need to do is visit its link through your browser.

As an example: https://dev.test.local/adminer.php
```

Tutorials:

1. [How to use Adminer:](https://kinsta.com/blog/adminer/) 


<br>

# 6. Related projects
1. [Nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)
2. [Mkcert-for-nginx-proxy](https://github.com/aegypius/mkcert-for-nginx-proxy)
