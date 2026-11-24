# Pinned base images. Node 24 is LTS until April 2028.
ARG NODE_IMAGE=node:24-bookworm-slim
ARG DOCKER_CLI_IMAGE=docker:29-cli

FROM ${DOCKER_CLI_IMAGE} AS dockercli

FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM ${NODE_IMAGE} AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM ${NODE_IMAGE} AS develop
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN apt-get update \
	&& apt-get install -y --no-install-recommends bash curl git jq ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

ENV NODE_ENV=development \
	WEBUI_HOST=0.0.0.0 \
	WEBUI_PORT=7777 \
	PORT=7777 \
	HOSTNAME=0.0.0.0 \
	WATCHPACK_POLLING=true \
	CHOKIDAR_USEPOLLING=true

EXPOSE 7777
# Daily version catalog. catalog_refresh.sh lives on the mounted ENV_DIR tree,
# not in this image. Once a day it rewrites .env-core/data/catalog.json and
# appends to .env-core/data/catalog-refresh.log. The dev server starts after that.
CMD ["sh", "-c", "if [ -n \"${ENV_DIR:-}\" ] && [ -f \"${ENV_DIR}/.env-core/sh/project/setup/versions/catalog_refresh.sh\" ]; then mkdir -p \"${ENV_DIR}/.env-core/data\"; bash \"${ENV_DIR}/.env-core/sh/project/setup/versions/catalog_refresh.sh\" loop >>\"${ENV_DIR}/.env-core/data/catalog-refresh.log\" 2>&1 & fi; exec npm run dev"]

FROM ${NODE_IMAGE} AS runner
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN apt-get update \
	&& apt-get install -y --no-install-recommends bash curl git jq ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV NODE_ENV=production \
	WEBUI_HOST=0.0.0.0 \
	WEBUI_PORT=7777 \
	PORT=7777 \
	HOSTNAME=0.0.0.0

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 7777
# Daily version catalog. catalog_refresh.sh lives on the mounted ENV_DIR tree,
# not in this image. Once a day it rewrites .env-core/data/catalog.json and
# appends to .env-core/data/catalog-refresh.log. The Web UI starts after that.
CMD ["sh", "-c", "if [ -n \"${ENV_DIR:-}\" ] && [ -f \"${ENV_DIR}/.env-core/sh/project/setup/versions/catalog_refresh.sh\" ]; then mkdir -p \"${ENV_DIR}/.env-core/data\"; bash \"${ENV_DIR}/.env-core/sh/project/setup/versions/catalog_refresh.sh\" loop >>\"${ENV_DIR}/.env-core/data/catalog-refresh.log\" 2>&1 & fi; exec node server.js"]
