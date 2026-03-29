# Makefile for Fitness Platform Infrastructure

# Variables
NETWORK_NAME := webproxy
WP_DIR := fitness-platform
CADDY_DIR := caddy
DOZZLE_DIR := dozzle
MONITORING_DIR := monitoring

# Phony targets ensure Make doesn't confuse these commands with actual files
.PHONY: help install up down restart logs-wp logs-caddy logs-monitoring backup shell-wp shell-db update clean

# Default command when typing just `make`
help:
	@echo "Fitness Platform Management"
	@echo "--------------------------------------------------------"
	@echo "make install         - First-time setup (creates .env if missing)"
	@echo "make up              - Build and start the entire stack"
	@echo "make down            - Stop and tear down the entire stack"
	@echo "make restart         - Restart the entire stack"
	@echo "make logs-wp         - View real-time logs for WordPress/PHP/DB"
	@echo "make logs-caddy      - View real-time logs for Caddy (SSL/Proxy)"
	@echo "make logs-monitoring - View real-time logs for Alloy/cAdvisor"
	@echo "make backup          - Manually trigger the backup script now"
	@echo "make shell-wp        - Drop into the WordPress PHP container shell"
	@echo "make shell-db        - Drop into the MariaDB container shell"
	@echo "make update          - Pull latest Docker images and recreate"
	@echo "make clean           - DANGER: Remove all containers, volumes, and networks"

# Setup initial environment
install:
	@if [ ! -f .env ]; then \
		echo "Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "Please edit .env with your real passwords before running 'make up'"; \
	else \
		echo ".env file already exists."; \
	fi

# Create the proxy network if it doesn't exist
create-network:
	@docker network ls | grep -q $(NETWORK_NAME) || docker network create $(NETWORK_NAME)

# Start everything
up: create-network
	@echo "Building and starting WordPress stack..."
	@cd $(WP_DIR) && docker compose build && docker compose up -d
	@echo "Starting Dozzle Log Viewer..."
	@cd $(DOZZLE_DIR) && docker compose up -d
	@echo "Starting Caddy gateway..."
	@cd $(CADDY_DIR) && docker compose up -d
	@echo "Starting monitoring stack..."
	@cd $(MONITORING_DIR) && docker compose up -d
	@echo "All systems go! Your platform is live."

# Stop everything
down:
	@echo "Stopping Caddy gateway..."
	@cd $(CADDY_DIR) && docker compose down
	@echo "Stopping monitoring stack..."
	@cd $(MONITORING_DIR) && docker compose down
	@echo "Stopping Dozzle..."
	@cd $(DOZZLE_DIR) && docker compose down
	@echo "Stopping WordPress stack..."
	@cd $(WP_DIR) && docker compose down
	@echo "All services stopped."

# Restart everything
restart: down up

# View WordPress stack logs
logs-wp:
	@cd $(WP_DIR) && docker compose logs -f

# View Caddy gateway logs
logs-caddy:
	@cd $(CADDY_DIR) && docker compose logs -f

# View monitoring stack logs
logs-monitoring:
	@cd $(MONITORING_DIR) && docker compose logs -f

# Manually trigger a backup immediately (great before running WordPress updates)
backup:
	@echo "Triggering manual backup inside container..."
	@docker exec -it fitness_backup /backup.sh

# Open a shell inside the PHP container (Useful for WP-CLI commands)
shell-wp:
	@docker exec -it fitness_php sh

# Open a shell inside the Database container (Useful for raw SQL queries)
shell-db:
	@docker exec -it fitness_db bash

# Pull latest images and restart
update:
	@echo "Pulling latest images..."
	@cd $(WP_DIR) && docker compose pull
	@cd $(CADDY_DIR) && docker compose pull
	@cd $(DOZZLE_DIR) && docker compose pull
	@cd $(MONITORING_DIR) && docker compose pull
	@$(MAKE) up

# Danger Zone: Completely wipe the infrastructure
clean: down
	@echo "Removing Docker volumes..."
	@cd $(WP_DIR) && docker compose down -v
	@cd $(CADDY_DIR) && docker compose down -v
	@cd $(DOZZLE_DIR) && docker compose down -v
	@cd $(MONITORING_DIR) && docker compose down -v
	@echo "Removing network..."
	@docker network rm $(NETWORK_NAME) || true
	@echo "Infrastructure wiped."
