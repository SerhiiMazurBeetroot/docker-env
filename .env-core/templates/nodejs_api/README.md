# docker-env Template for Node.js API

This repository is the docker-env template for an Express API. It includes the Compose file, the Node Dockerfile, and a small server with `GET /` and `GET /health`.

The app listens on port 3000 inside the container. Nginx Proxy uses `VIRTUAL_PORT=3000`. `{DOMAIN_NAME}` and `{DOMAIN_FULL}` in the Compose file and `.env.example` are replaced when a site is created.

## Usage

These files are used by docker-env. Clone that repository first:

```bash
git clone https://github.com/SerhiiMazurBeetroot/docker-env.git
```

The GitHub name docker-env uses for this template is `docker-env-template-nodejs_api`.

## License

This project is licensed under the [MIT License](LICENSE).
