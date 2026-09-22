# System services

Shared pieces every project uses: reverse proxy, local TLS, hosts entries, log viewer, and mail catcher.

## Nginx proxy

Containers:

| Name | Role |
| --- | --- |
| `nginx-proxy` | [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy) — routes by `VIRTUAL_HOST` |
| `nginx-mkcert` | Issues certs into the `ssl-certs` volume |
| `nginx-dozzle` | Log UI |
| `nginx-webui` | Dashboard (started with Nginx, can be stopped alone) |

Published ports:

| Port | Service |
| --- | --- |
| **443** | HTTPS for `*.local` sites |
| **8080** | HTTP on the proxy (container port 80) |
| **7007** | Dozzle |
| **7777** | Web UI (bound to `127.0.0.1`) |

Network: `dockerwp`. Volume: `ssl-certs`.

CLI: **1 System → 1 Nginx**

| Key | Action |
| --- | --- |
| 1 Setup | Create network/volume if needed, start proxy + mkcert + Dozzle, try Web UI |
| 2 Stop | `docker compose down` on the Nginx stack |
| 3 Start | Start proxy stack if it is down |
| 4 Restart | Restart `nginx-proxy` only |
| 5 Rebuild | Recreate nginx, mkcert, dozzle |
| 6 Re-Setup | Stop, delete `ssl-certs` and `certs-root`, Setup again |

After Re-Setup, [trust the CA](#trust-the-local-ca) again.

## Trust the local CA

mkcert writes the root CA to `.env-core/system/nginx/certs-root/` (`rootCA.pem`). Certificates for running hosts are created automatically. You install the **root** once per machine.

### Windows

1. Open `.env-core/system/nginx/certs-root/`
2. Copy `rootCA.pem` to `rootCA.crt` if the wizard needs a `.crt`
3. Open the file and install into **Trusted Root Certification Authorities**

Screenshots:

1. [Install](../.env-core/docs/images/certs-1.jpg)
2. [Store location](../.env-core/docs/images/certs-2.jpg)
3. [Select store](../.env-core/docs/images/certs-3.jpg)
4. [Import](../.env-core/docs/images/certs-4.jpg)
5. [Confirm](../.env-core/docs/images/certs-5.jpg)

Microsoft: [Installing a trusted root certificate](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/installing-a-test-certificate-on-a-test-computer).

### macOS

Open `rootCA.pem` in Keychain Access, add it to the **login** or **System** keychain, then set Trust → **Always Trust** for SSL.

### Linux

Copy the PEM into the OS trust store (often `/usr/local/share/ca-certificates`) and update certificates (`update-ca-certificates` on Debian/Ubuntu). Firefox may need its own authority store.

Restart the browser after installing. If you Re-Setup Nginx, replace the old root with the new one.

## Hosts file

Each site needs `127.0.0.1` → `DOMAIN_FULL` plus extras (`*.phpmyadmin`, `*.mail`, `*.pgadmin`, `*.kibana`, …).

macOS and Linux: create/delete updates `/etc/hosts` with sudo.

Windows: the CLI prints the line. Edit `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```text
127.0.0.1 dev.blog.local dev.blog.local.phpmyadmin dev.blog.local.mail
```

The Web UI can add or remove extra names when `/etc/hosts` is mounted into `nginx-webui`. If that fails, use the CLI.

## Dozzle

[http://127.0.0.1:7007](http://127.0.0.1:7007) — live logs for all Docker containers. The Web UI links a service to its Dozzle page.

## Mail (WordPress / Bedrock)

Outgoing mail is caught on `https://{DOMAIN_FULL}.mail` (MailHog-style host). Add that name to hosts (the extra hosts line includes it).

## Database UIs

These are per-project virtual hosts, not ports on localhost:

| Stack | URL pattern |
| --- | --- |
| WordPress / Bedrock | `https://{DOMAIN_FULL}.phpmyadmin` |
| Directus | `https://{DOMAIN_FULL}.pgadmin` |

## Git tokens

**3 Project Services → 5 Tools → 2 GIT → 5 Repo access** stores GitHub/GitLab tokens in `.env-core/data/settings.log` (gitignored). Needed only to create remote repos from the CLI.

- [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GitLab personal access token](https://docs.gitlab.com/user/profile/personal_access_tokens/)
