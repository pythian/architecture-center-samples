# Default settings
PROJECT_NAME := oracle-ebs-toolkit
PROJECT ?= $(PROJECT_NAME)
PROJECT_ID ?= $(shell gcloud config get-value project 2>/dev/null)
PROJECT_ID_CLEAN := $(shell echo $(PROJECT_ID) | awk -F':' '{print $$NF}')
export TF_VAR_project_id := $(PROJECT_ID_CLEAN)
PROJECT_SA_EMAIL := jde-project-service-account@$(PROJECT_ID_CLEAN).iam.gserviceaccount.com

# Directory for Terraform
TF_DIR := .

# Required GCP IAM roles
REQUIRED_ROLES = roles/storage.admin roles/iam.serviceAccountUser roles/iap.tunnelResourceAccessor roles/compute.osAdminLogin  roles/compute.instanceAdmin.v1

.PHONY: help setup init format lint validate plan deploy destroy docs verify-gcp-access vision_plan vision_deploy vision_destroy

help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | awk 'BEGIN {FS = ":.*?##"}; {printf "  make %-20s %s\n", $$1, $$2}'

setup: ## Run initial setup for the project
	@echo "Running setup..."
	bash scripts/install.sh
	@echo "Setup complete."
	@echo "Make sure you are setup with gcloud init with the project that will be used for this deployment and proceed to verify-gcp-access'."

init: ## Initialize Terraform configuration
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "PROJECT_ID not set"; exit 1; \
	fi
	@PROJECT_NUMBER=$$(gcloud projects describe $(PROJECT_ID) --format="value(projectNumber)"); \
	BUCKET_NAME="gs://$(PROJECT_ID_CLEAN)-$${PROJECT_NUMBER}-terraform-state"; \
	echo "Checking if backend bucket $$BUCKET_NAME exists..."; \
	if ! gcloud storage ls -b $$BUCKET_NAME >/dev/null 2>&1; then \
		echo "Bucket does not exist. Creating..."; \
		gcloud storage buckets create $$BUCKET_NAME \
			--location=US --uniform-bucket-level-access; \
		echo "Waiting 10s for bucket propagation..."; \
		sleep 10; \
	fi; \
	echo "Initializing Terraform in $(TF_DIR)..."; \
	terraform -chdir=$(TF_DIR) init -reconfigure \
		-backend-config="bucket=$(PROJECT_ID_CLEAN)-$${PROJECT_NUMBER}-terraform-state" \
		-backend-config="prefix=$(PROJECT_ID_CLEAN)"
	@echo "Terraform initialized successfully."

format: ## Format Terraform files
	terraform -chdir=$(TF_DIR) fmt

lint: ## Lint Terraform files
	pre-commit run --all-files

validate: ## Validate Terraform configuration
	terraform -chdir=$(TF_DIR) validate \
	  -var="project_id=$(PROJECT_ID_CLEAN)" \
	  -var="project_service_account_email=$(PROJECT_SA_EMAIL)"
	@echo "Terraform configuration is valid."

deploy_oracle_ebs_scripts: ## Deploy Oracle EBS scripts to instances
	@echo ""
	@echo "\033[1m>>> Getting EBS instance zone from Terraform output \033[0m"
	@ebs_gce_zone=$$(terraform -chdir=$(TF_DIR) output -raw apps_instance_zone); \
	echo "Zone: $$ebs_gce_zone"; \
	echo ""; \
	echo "\033[1m>>> Creating /scripts on oracle-ebs-db \033[0m"; \
	gcloud compute ssh --zone "$$ebs_gce_zone" "oracle-ebs-db" --tunnel-through-iap --project $(PROJECT_ID_CLEAN) \
	  --command "sudo mkdir -vp /scripts && sudo chmod -v 777 /scripts"; \
	echo ""; \
	echo "\033[1m>>> Copying /scripts/* to oracle-ebs-db \033[0m"; \
	gcloud compute scp --tunnel-through-iap --zone "$$ebs_gce_zone" --project=$(PROJECT_ID_CLEAN) \
	scripts/ebs/* oracle-ebs-db:/scripts; \
	echo ""; \
	echo "\033[1m>>> Creating /scripts on oracle-ebs-apps \033[0m"; \
	gcloud compute ssh --zone "$$ebs_gce_zone" "oracle-ebs-apps" --tunnel-through-iap --project $(PROJECT_ID_CLEAN) \
	  --command "sudo mkdir -vp /scripts && sudo chmod -v 777 /scripts"; \
	echo ""; \
	echo "\033[1m>>> Copying /scripts/* to oracle-ebs-apps \033[0m"; \
	gcloud compute scp --tunnel-through-iap --zone "$$ebs_gce_zone" --project=$(PROJECT_ID_CLEAN) \
	scripts/ebs/* oracle-ebs-apps:/scripts

VISION ?= false

jde_demo_plan: ## Plan Terraform configuration with Oracle EBS Vision
	terraform -chdir=$(TF_DIR) plan \
	  -var="project_id=$(PROJECT_ID_CLEAN)" \
	  -var="project_service_account_email=$(PROJECT_SA_EMAIL)" \
	  -var="oracle_jde_vision=true"

jde_demo_deploy: ## Apply Terraform configuration with Oracle EBS Vision
	terraform -chdir=$(TF_DIR) apply -auto-approve \
	  -var="project_id=$(PROJECT_ID_CLEAN)" \
	  -var="project_service_account_email=$(PROJECT_SA_EMAIL)" \
	  -var="oracle_jde_vision=true"

jde_demo_destroy: ## Destroy Terraform configuration with Oracle EBS Vision
	terraform -chdir=$(TF_DIR) destroy -auto-approve \
	  -var="project_id=$(PROJECT_ID_CLEAN)" \
	  -var="project_service_account_email=$(PROJECT_SA_EMAIL)" \
	  -var="oracle_jde_vision=true"

jde_demo_deploy_soft: ## Install JDE requried software on the instances
	@echo ""
	@echo "\033[1m>>> Getting JDE instance zone from Terraform output \033[0m"
	@jde_gce_zone=$$(terraform -chdir=$(TF_DIR) output -raw vision_instance_zone); \
	echo "Zone: $$jde_gce_zone"; \
	echo ""; \
	echo "\033[1m>>> Copying FUNCT to JDE provision instance \033[0m"; \
	gcloud compute scp --tunnel-through-iap --zone "$$jde_gce_zone" --project=$(PROJECT_ID_CLEAN) \
	scripts/jde/functions.sh jde-demo-prov:~; \
	echo ""; \
	echo "\033[1m>>> Running JDE Software provisioning \033[0m"; \
	gcloud compute ssh --zone "$$jde_gce_zone" "jde-demo-prov" --tunnel-through-iap --project $(PROJECT_ID_CLEAN) \
	  --command "source functions.sh; stage_weblogic;" -- -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=20



verify-gcp-access: ## Verify GCP access and required IAM roles
	@if [ -z "$(PROJECT_ID_CLEAN)" ]; then \
		echo " PROJECT_ID is not set and could not be auto-detected from gcloud config."; \
		echo "Please run: gcloud init OR pass PROJECT_ID=<id> to make."; \
		exit 1; \
	fi
	@echo " Verifying GCP access for project: $(PROJECT_ID_CLEAN)"
	@if ! gcloud auth list --format="value(account)" 2>/dev/null | grep -q .; then \
		echo "⚠ No active gcloud authentication found. Please run: gcloud init"; \
		exit 1; \
	fi
	@if ! gcloud projects describe "$(PROJECT_ID_CLEAN)" --quiet >/dev/null 2>&1; then \
		echo " Cannot access project: $(PROJECT_ID_CLEAN)"; \
		exit 1; \
	fi
	@echo "Access to project $(PROJECT_ID_CLEAN) confirmed."
	@CURRENT_ACCOUNT=$$(gcloud config get-value account 2>/dev/null); \
	echo " Checking IAM roles for $$CURRENT_ACCOUNT..."; \
	USER_ROLES=$$(gcloud projects get-iam-policy "$(PROJECT_ID_CLEAN)" \
		--flatten="bindings[].members" \
		--format="table(bindings.role)" \
		--filter="bindings.members:user:$$CURRENT_ACCOUNT" | tail -n +2); \
	if echo "$$USER_ROLES" | grep -Eq "(roles/owner|roles/editor)"; then \
		echo " User has Owner/Editor role → skipping fine-grained permission checks."; \
	else \
		MISSING=0; \
		for role in $(REQUIRED_ROLES); do \
			if echo "$$USER_ROLES" | grep -q $$role; then \
				echo "Has role: $$role"; \
			else \
				echo " Missing role: $$role"; \
				MISSING=1; \
			fi; \
		done; \
		if [ $$MISSING -ne 0 ]; then \
			echo " Missing required IAM roles. Please update permissions before proceeding."; \
			exit 1; \
		fi; \
	fi; \
	echo ""; \
	echo " GCP access check passed for project: $(PROJECT_ID_CLEAN)"

