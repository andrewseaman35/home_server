.PHONY: build run stop restart logs clean network help tf-init tf-plan tf-apply create-env test venv install clean-venv

# Variables
IMAGE_NAME = aws_notify
CONTAINER_NAME = aws_notify
NETWORK_NAME = my_network
PORT = 5889
TF_DIR = terraform
VENV = .venv
PYTHON = python3

help:
	@echo "Available commands:"
	@echo "  make build         - Build the Docker image"
	@echo "  make run          - Run the container (creates network if needed)"
	@echo "  make stop         - Stop and remove the container"
	@echo "  make restart      - Restart the container"
	@echo "  make logs         - View container logs"
	@echo "  make clean        - Stop container and remove image"
	@echo "  make network      - Create Docker network"
	@echo "  make tf-init      - Initialize Terraform"
	@echo "  make tf-plan      - Plan Terraform changes"
	@echo "  make tf-apply     - Apply Terraform changes"
	@echo "  make create-env   - Create .env file from Terraform outputs"
	@echo "  make setup-all    - Full setup: apply Terraform and create .env"
	@echo "  make test         - Run health check test"
	@echo "  make venv         - Create Python virtual environment"
	@echo "  make install      - Install Python dependencies in virtual environment"
	@echo "  make clean-venv   - Remove Python virtual environment"
	@echo "  make help         - Show this help message"

build:
	docker build -t $(IMAGE_NAME) .

network:
	docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create $(NETWORK_NAME)

run: network
	docker run -d \
		--name $(CONTAINER_NAME) \
		--network $(NETWORK_NAME) \
		--env-file .env \
		-p $(PORT):$(PORT) \
		--restart unless-stopped \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

restart: stop run

logs:
	docker logs -f $(CONTAINER_NAME)

clean: stop
	docker rmi $(IMAGE_NAME) || true

# Terraform commands
tf-init:
	cd $(TF_DIR) && terraform init

tf-plan:
	cd $(TF_DIR) && terraform plan

tf-apply:
	cd $(TF_DIR) && terraform apply -auto-approve

# Create .env file from Terraform outputs
create-env:
	@echo "Creating .env file from Terraform outputs..."
	@cd $(TF_DIR) && { \
		echo "AWS_ACCESS_KEY_ID=$$(terraform output -raw service_user_access_key_id)"; \
		echo "AWS_SECRET_ACCESS_KEY=$$(terraform output -raw service_user_secret_access_key)"; \
		echo "AWS_REGION=$$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")"; \
		echo "AWS_SNS_TOPIC_ARN=$$(terraform output -raw sns_topic_arn)"; \
	} > ../.env
	@echo ".env file created successfully"

# Full setup command
setup-all: tf-apply create-env

# Virtual environment management
venv:
	@echo "Creating virtual environment..."
	@test -d $(VENV) || $(PYTHON) -m venv $(VENV)
	@echo "Virtual environment created at $(VENV)"
	@echo "To activate, run: source $(VENV)/bin/activate"

install: venv
	@echo "Installing Python dependencies..."
	@. $(VENV)/bin/activate && pip install -r requirements.txt
	@echo "Dependencies installed successfully"

clean-venv:
	@echo "Removing virtual environment..."
	rm -rf $(VENV)
	@echo "Virtual environment removed"

# Test command (now uses virtualenv)
test: install
	@echo "Running health check test..."
	@. $(VENV)/bin/activate && python test_service.py