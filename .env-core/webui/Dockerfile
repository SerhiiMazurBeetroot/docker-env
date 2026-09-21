FROM docker:27-cli AS dockercli

FROM node:20-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM node:20-bookworm-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-bookworm-slim AS develop
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN apt-get update \
	&& apt-get install -y --no-install-recommends bash jq ca-certificates \
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
CMD ["npm", "run", "dev"]

FROM node:20-bookworm-slim AS runner
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN apt-get update \
	&& apt-get install -y --no-install-recommends bash jq ca-certificates \
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
CMD ["node", "server.js"]
