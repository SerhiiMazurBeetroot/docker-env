### [Return to README.MD](../../README.MD#6-how-to)
----------------------------------

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
| 4    | Install certificate   | [screen 1](./.env-core/docs/images/certs-1.jpg) |
| 5    | Choose store location | [screen 2](./.env-core/docs/images/certs-2.jpg) |
| 6    | Select store          | [screen 3](./.env-core/docs/images/certs-3.jpg) |
| 7    | Import certificate    | [screen 4](./.env-core/docs/images/certs-4.jpg) |
| 8    | Confirm install       | [screen 5](./.env-core/docs/images/certs-5.jpg) |
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
In this envinronment used Adminer and phpMyAdmin database management tool.

To access any database, all you need to do is visit its link through your browser.

Adminer: https://dev.test.local/adminer.php

phpMyAdmin: https://dev.test.local.phpmyadmin
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

----------------------------------
### [Return to README.MD](../../README.MD#6-how-to)
