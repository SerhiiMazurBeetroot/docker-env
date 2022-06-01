### [Return to README.MD](../../README.MD)
----------------------------------
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
| 5    |         | Enter DOMAIN_FULL         | test.local     | * |
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

----------------------------------
### [Return to README.MD](../../README.MD)
