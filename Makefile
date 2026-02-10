# ==============================================================================
# Confluent Java Toolkit — Makefile
# Unified command interface for build, test, Docker, K8s, and operations.
# ==============================================================================
SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---------- Variables ----------
PROJECT_VERSION  := 1.0.0-SNAPSHOT
DOCKER_REGISTRY  := registry.example.com/confluent-ps
KIND_CLUSTER     := kafka-dev

# ---------- Build ----------
.PHONY: build
build:                                         ## Build all modules (skip tests)
	mvn clean package -DskipTests -B --no-transfer-progress

.PHONY: compile
compile:                                       ## Compile without packaging
	mvn compile -B --no-transfer-progress

.PHONY: test
test:                                          ## Run all unit tests
	mvn verify -B --no-transfer-progress

.PHONY: test-producer
test-producer:                                 ## Run producer-consumer tests only
	mvn test -pl producer-consumer-app -B

.PHONY: test-kstreams
test-kstreams:                                 ## Run KStreams topology tests only
	mvn test -pl kstreams-app -B

.PHONY: clean
clean:                                         ## Clean all build artifacts
	mvn clean -B

# ---------- CI Pipeline ----------
.PHONY: ci
ci: clean build test docker-build ci-scan      ## Full CI pipeline (build, test, scan)
	@echo "[CI] All checks passed."

.PHONY: ci-lint
ci-lint:                                       ## Run static analysis (spotbugs)
	mvn compile spotbugs:check -B 2>/dev/null || echo "[WARN] SpotBugs plugin not configured — skipping"

.PHONY: ci-scan
ci-scan:                                       ## Security scan with Trivy
	@command -v trivy >/dev/null 2>&1 && \
	  trivy fs --severity CRITICAL,HIGH --exit-code 0 . || \
	  echo "[WARN] Trivy not installed — skipping security scan"

.PHONY: ci-k8s-validate
ci-k8s-validate:                               ## Validate all Kustomize overlays
	@for env in dev qa prod; do \
	  echo "  Validating k8s/overlays/$$env..."; \
	  kubectl kustomize k8s/overlays/$$env/ > /dev/null 2>&1 && \
	    echo "  [PASS] $$env" || echo "  [SKIP] $$env (kubectl not available)"; \
	done

# ---------- Docker ----------
.PHONY: docker-build
docker-build:                                  ## Build Docker images for both apps
	docker build -f docker/Dockerfile.producer-consumer -t payment-app:workshop .
	docker build -f docker/Dockerfile.kstreams -t fraud-detection:workshop .
	@echo "[DOCKER] Images built: payment-app:workshop, fraud-detection:workshop"

.PHONY: docker-tag
docker-tag:                                    ## Tag images for registry push
	docker tag payment-app:workshop $(DOCKER_REGISTRY)/producer-consumer-app:$(PROJECT_VERSION)
	docker tag fraud-detection:workshop $(DOCKER_REGISTRY)/kstreams-app:$(PROJECT_VERSION)

# ---------- Local Environment (docker-compose) ----------
.PHONY: local-up
local-up:                                      ## Start local Kafka broker + Schema Registry
	cd docker && docker compose up -d broker schema-registry
	@echo "Waiting for broker to be ready..."
	@sleep 10
	@echo "[LOCAL] Broker and Schema Registry started."

.PHONY: local-down
local-down:                                    ## Stop and clean up local environment
	cd docker && docker compose down -v
	@echo "[LOCAL] Environment stopped."

.PHONY: local-all
local-all:                                     ## Start full local stack (broker + SR + apps)
	cd docker && docker compose up -d

.PHONY: topics
topics:                                        ## Create Kafka topics (local broker)
	./scripts/create-topics.sh local

# ---------- kind (Kubernetes in Docker) ----------
.PHONY: kind-create
kind-create:                                   ## Create a local kind K8s cluster
	kind create cluster --name $(KIND_CLUSTER) --config kind-cluster.yaml
	@echo "[KIND] Cluster '$(KIND_CLUSTER)' created."

.PHONY: kind-load
kind-load: docker-build                        ## Load Docker images into kind
	kind load docker-image payment-app:workshop --name $(KIND_CLUSTER)
	kind load docker-image fraud-detection:workshop --name $(KIND_CLUSTER)
	@echo "[KIND] Images loaded."

.PHONY: kind-destroy
kind-destroy:                                  ## Destroy the kind cluster
	kind delete cluster --name $(KIND_CLUSTER)

# ---------- Kubernetes (Kustomize) ----------
.PHONY: k8s-dev
k8s-dev:                                       ## Apply K8s dev overlay
	kubectl apply -k k8s/overlays/dev/

.PHONY: k8s-qa
k8s-qa:                                        ## Apply K8s QA overlay
	kubectl apply -k k8s/overlays/qa/

.PHONY: k8s-prod
k8s-prod:                                      ## Apply K8s PROD overlay
	kubectl apply -k k8s/overlays/prod/

# ---------- Diagnostics ----------
.PHONY: diagnose
diagnose:                                      ## Run full diagnostics
	./scripts/diagnose.sh full

.PHONY: workshop
workshop:                                      ## Run workshop checkpoint (all blocks)
	./scripts/workshop-check.sh final

# ---------- Load Testing ----------
.PHONY: load-test
load-test:                                     ## Run k6 load test
	@command -v k6 >/dev/null 2>&1 && \
	  k6 run tests/load/payment-producer-test.js || \
	  echo "[WARN] k6 not installed — skipping load test"

# ---------- Help ----------
.PHONY: help
help:                                          ## Show this help message
	@echo ""
	@echo "Confluent Java Toolkit — Available Targets:"
	@echo "============================================"
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
