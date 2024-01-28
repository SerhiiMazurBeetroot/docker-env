# Define your service name if needed
SERVICE_NAME := myservice

# Start services defined in your docker-compose.yml
up:
	docker compose up

# Start services defined in your docker-compose.yml
upq:
	docker compose up -d

# Stop running containers without removing them
stop:
	docker compose stop

# Stop and remove containers, networks, images, and volumes
down:
	docker compose down

# Rebuild the containers
rebuild:
	docker compose up -d --build

# View logs of the service
logs:
	docker compose logs -f $(SERVICE_NAME)

# Execute commands in a running container
# Example usage: make exec SERVICE_NAME=myservice CMD="ls -l"
exec:
	docker compose exec $(SERVICE_NAME) $(CMD)

# Run a one-off command in a new container instance
# Example usage: make run CMD="echo hello"
run-cmd:
	docker compose run --rm $(SERVICE_NAME) $(CMD)

# Shortcut for rebuilding and starting services
restart: down up

.PHONY: up stop down rebuild logs exec run-cmd restart

