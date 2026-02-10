# Confluent Cloud — Java Developer Runbook

> **Payment Processing Pipeline** — Producer/Consumer & Kafka Streams on Confluent Cloud
> PCI-DSS compliant | Git-Flow | GitOps | Kubernetes

---

## Table of Contents

1. [Overview](#1-overview)
2. [Requirements](#2-requirements)
3. [Repository Structure](#3-repository-structure)
4. [Application Lifecycle](#4-application-lifecycle)
   - [4.1 Local Development (DEV)](#41-local-development-dev)
   - [4.2 Build & Test (CI)](#42-build--test-ci)
   - [4.3 QA / Staging](#43-qa--staging)
   - [4.4 Production Release](#44-production-release)
5. [Git-Flow Branching Model](#5-git-flow-branching-model)
6. [GitOps Deployment Model](#6-gitops-deployment-model)
7. [Configuration Management](#7-configuration-management)
8. [PCI-DSS Compliance](#8-pci-dss-compliance)
9. [Developer Toolbox](#9-developer-toolbox)
10. [Troubleshooting & Diagnostics](#10-troubleshooting--diagnostics)
11. [Appendix](#11-appendix)

---

## 1. Overview

This runbook describes the complete lifecycle for building, testing, and operating **Java applications on Confluent Cloud**. It covers two reference applications:

| Application | Description | Module |
|---|---|---|
| **Payment Producer/Consumer** | Publishes and consumes masked payment events (PCI-DSS) | `producer-consumer-app` |
| **Fraud Detection (KStreams)** | Real-time fraud scoring via Kafka Streams topology | `kstreams-app` |

### Architecture

```
┌─────────────┐    payments     ┌───────────────────┐    fraud-alerts     ┌────────────┐
│  Payment     │ ──────────────►│  Fraud Detection   │ ──────────────────►│  Alert     │
│  Producer    │                │  (Kafka Streams)   │                    │  Consumer  │
└─────────────┘                │                    │                    └────────────┘
                               │  approved-payments │
                               │ ──────────────────►│  Downstream
                               └───────────────────┘   Systems
```

### Environment Promotion Model

```
  DEV (manual)          QA (scripted)           PROD (GitOps handover)
┌──────────────┐    ┌──────────────────┐    ┌─────────────────────────┐
│ Local broker │    │ Confluent Cloud  │    │ Confluent Cloud         │
│ docker-compose│──►│ Dedicated cluster│──►│ Dedicated cluster       │
│ Self-service │    │ CI/CD automated  │    │ PR-based, Ops approval  │
│ Manual tasks │    │ Config in files  │    │ Code + Config via GitHub│
└──────────────┘    └──────────────────┘    └─────────────────────────┘
```

---

## 2. Requirements

### 2.1 Developer Workstation

| Tool | Version | Purpose |
|---|---|---|
| **JDK** | 17+ (Temurin) | Java compilation and runtime |
| **Maven** | 3.9+ | Build tool |
| **Docker** | 24+ | Container builds, local Kafka |
| **docker-compose** | 2.x | Local environment orchestration |
| **Confluent CLI** | 3.x | Confluent Cloud management |
| **kubectl** | 1.28+ | Kubernetes cluster interaction |
| **kustomize** | 5.x | K8s manifest management |
| **kcat (kafkacat)** | 1.7+ | Low-level Kafka debugging |
| **Git** | 2.40+ | Version control |
| **gh** | 2.x | GitHub CLI for PRs |

### 2.2 Confluent Cloud Access

| Resource | DEV | QA | PROD |
|---|---|---|---|
| Cluster type | Basic (shared) | Dedicated | Dedicated |
| API Keys | Developer-managed | CI/CD-managed | Vault-managed |
| Schema Registry | Shared | Shared | Dedicated |
| Topics | Self-service | Scripted (IaC) | GitOps (PR) |

### 2.3 PCI-DSS Requirements Summary

| PCI-DSS Req | Control | Implementation |
|---|---|---|
| **Req 1** | Network segmentation | K8s NetworkPolicy, VPC peering |
| **Req 2** | No default credentials | Unique API keys per environment |
| **Req 3** | Protect stored data | Card numbers masked before producing |
| **Req 4** | Encrypt in transit | SASL_SSL to Confluent Cloud |
| **Req 6** | Secure development | CI security scans, code review |
| **Req 7** | Restrict access | RBAC, least-privilege API keys |
| **Req 8** | Identify users | client.id in all Kafka configs |
| **Req 10** | Logging & monitoring | Structured logs, audit trail |
| **Req 11** | Regular testing | Automated tests in CI |
| **Req 12** | Security policy | This runbook + change management |

---

## 3. Repository Structure

```
confluent-java-toolkit/
├── pom.xml                              # Parent POM (multi-module)
│
├── producer-consumer-app/
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── avro/payment.avsc        # Avro schema (PCI-DSS compliant)
│       │   ├── java/io/confluent/ps/
│       │   │   ├── config/ConfigLoader.java
│       │   │   ├── producer/PaymentProducer.java
│       │   │   └── consumer/PaymentConsumer.java
│       │   └── resources/
│       │       ├── application.properties
│       │       ├── application-dev.properties
│       │       ├── application-qa.properties
│       │       ├── application-prod.properties
│       │       └── logback.xml
│       └── test/java/.../PaymentProducerTest.java
│
├── kstreams-app/
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── avro/
│       │   │   ├── payment.avsc
│       │   │   └── fraud_alert.avsc
│       │   ├── java/io/confluent/ps/kstreams/
│       │   │   ├── FraudDetectionApp.java
│       │   │   └── topology/FraudDetectionTopology.java
│       │   └── resources/
│       │       ├── application.properties
│       │       ├── application-{dev,qa,prod}.properties
│       │       └── logback.xml
│       └── test/.../FraudDetectionTopologyTest.java
│
├── docker/
│   ├── Dockerfile.producer-consumer
│   ├── Dockerfile.kstreams
│   └── docker-compose.yml               # Local dev environment
│
├── k8s/
│   ├── base/                            # Kustomize base
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── secrets.yaml                 # TEMPLATE — never real secrets
│   │   ├── serviceaccount.yaml
│   │   ├── networkpolicy.yaml           # PCI-DSS Req 1
│   │   ├── producer-deployment.yaml
│   │   └── kstreams-deployment.yaml
│   └── overlays/
│       ├── dev/kustomization.yaml
│       ├── qa/kustomization.yaml
│       └── prod/kustomization.yaml
│
├── scripts/
│   ├── create-topics.sh                 # Topic provisioning
│   ├── diagnose.sh                      # Troubleshooting toolkit
│   └── ccloud-setup.sh                  # Confluent Cloud bootstrap
│
├── .github/workflows/
│   ├── ci.yaml                          # CI: build, test, scan
│   └── cd-gitops.yaml                   # CD: GitOps promotion
│
└── RUNBOOK.md                           # ← You are here
```

---

## 4. Application Lifecycle

### 4.1 Local Development (DEV)

> **Mode:** Manual, self-service. Developers run everything locally.

#### Step 1 — Start the Local Environment

```bash
# Start Kafka broker + Schema Registry
cd docker
docker-compose up -d broker schema-registry

# Verify the broker is healthy
docker exec broker kafka-topics --bootstrap-server localhost:9092 --list
```

#### Step 2 — Create Topics

```bash
./scripts/create-topics.sh local
```

Expected output:
```
==> Creating topics on local broker (localhost:9092)...
  [OK] payments
  [OK] fraud-alerts
  [OK] approved-payments
==> Done.
```

#### Step 3 — Build the Project

```bash
# From the repository root
mvn clean package -DskipTests
```

#### Step 4 — Run the Producer

```bash
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     produce
```

Output:
```
2026-02-09 10:15:32.001 [main] INFO  PaymentProducer - PaymentProducer started — sending to topic 'payments'
2026-02-09 10:15:32.450 [kafka-producer-network-thread] INFO  PaymentProducer - Sent payment txn_id=a1b2c3d4 partition=2 offset=0
```

#### Step 5 — Run the Consumer (in another terminal)

```bash
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     consume
```

#### Step 6 — Run the Kafka Streams App

```bash
java -Dapp.env=dev \
     -jar kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar
```

#### Step 7 — Run Unit Tests

```bash
mvn test
```

The `FraudDetectionTopologyTest` uses Kafka's `TopologyTestDriver` — no broker required:

```
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
```

#### Step 8 — Clean Up

```bash
cd docker
docker-compose down -v
```

---

### 4.2 Build & Test (CI)

> **Trigger:** Every push to `develop`, `release/*`, `hotfix/*`, or PR to `main`.

The CI pipeline (`.github/workflows/ci.yaml`) runs:

1. **Build & Unit Test** — `mvn verify`
2. **Container Image Build** — multi-stage Docker (on `develop`/`release/*` only)
3. **Security Scan** — Trivy vulnerability scanner (PCI-DSS Req 6.3)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Build & │────►│  Docker  │────►│ Security │
│  Test    │     │  Build   │     │  Scan    │
└──────────┘     └──────────┘     └──────────┘
```

#### Running the CI Locally

```bash
# Simulate the CI build
mvn verify -B --no-transfer-progress

# Build Docker images locally
docker build -f docker/Dockerfile.producer-consumer -t payment-app:local .
docker build -f docker/Dockerfile.kstreams -t fraud-detection:local .
```

---

### 4.3 QA / Staging

> **Mode:** Scripted. All parameters in config files. Automated deployment via CI/CD.

#### Prerequisites

- QA Confluent Cloud cluster provisioned (`./scripts/ccloud-setup.sh qa`)
- K8s namespace `confluent-apps-qa` exists
- Secrets stored in K8s Secrets (backed by Vault)

#### QA Deployment

QA deployment is **automatic** when CI passes on `develop`:

1. CI builds container images with SHA tag
2. CD pipeline updates `k8s/overlays/qa/kustomization.yaml` with the new image tag
3. ArgoCD / Flux detects the change and syncs

#### Manual QA Deployment (if needed)

```bash
# Apply QA overlay
kubectl apply -k k8s/overlays/qa/

# Verify pods
kubectl get pods -n confluent-apps-qa

# Check logs
kubectl logs -n confluent-apps-qa -l app=fraud-detection --tail=50 -f
```

#### QA Validation Checklist

- [ ] All pods in `Running` state
- [ ] Consumer lag is zero or decreasing
- [ ] Fraud alerts appear in `fraud-alerts` topic for high-risk test data
- [ ] No `ERROR` level log entries
- [ ] Schema Registry subjects registered correctly

---

### 4.4 Production Release

> **Mode:** GitOps handover. Code and configs submitted via GitHub PR. Operations team approves and merges.

#### Release Process (Git-Flow)

```bash
# 1. Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# 2. Bump version
mvn versions:set -DnewVersion=1.0.0
git add -A && git commit -m "chore: bump version to 1.0.0"

# 3. Push — triggers CI
git push -u origin release/1.0.0

# 4. CI passes → CD creates a PROD promotion PR automatically
#    The PR targets k8s/overlays/prod/ with the new image tags
#    and includes a PCI-DSS checklist.

# 5. Operations team reviews and approves the PR
# 6. Merge → ArgoCD/Flux deploys to PROD

# 7. After successful PROD deploy, merge release back:
git checkout main && git merge release/1.0.0 --no-ff
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin main --tags

git checkout develop && git merge release/1.0.0 --no-ff
git push origin develop
```

#### PROD Promotion PR Template

The CD pipeline automatically creates a PR that looks like:

```markdown
## Production Deployment Request

**Source branch:** release/1.0.0
**Image SHA:** abc123def456

### PCI-DSS Checklist
- [ ] Security scan passed (Trivy)
- [ ] QA sign-off obtained
- [ ] Change management ticket filed
- [ ] Rollback plan documented

### Approval Required
This PR requires approval from the operations team before merge.
```

#### Rollback

```bash
# Option 1: Revert the GitOps PR
git revert <merge-commit-sha>
git push origin main
# ArgoCD/Flux will roll back automatically

# Option 2: Manual K8s rollback
kubectl rollout undo deployment/fraud-detection -n confluent-apps-prod
kubectl rollout undo deployment/payment-producer -n confluent-apps-prod
```

---

## 5. Git-Flow Branching Model

```
main ─────────●──────────────────────●──────── (tagged releases only)
              │                      │
              │    release/1.0.0     │
              │  ┌────●────●────┐   │
              │  │              │   │
develop ──●───●──●──────────────●───●──●────── (integration branch)
          │      │              │      │
          │  feature/payment   │  feature/alerts
          │  ┌──●──●──┐       │  ┌──●──┐
          │  │        │       │  │     │
          └──┘        └───────┘  └─────┘

          hotfix/sec-patch
          ┌──●──┐
main ─────●     ●──── (hotfix merged to main AND develop)
```

### Branch Naming

| Branch | Purpose | Deploys to |
|---|---|---|
| `main` | Production-ready code | PROD (via tag) |
| `develop` | Integration branch | QA (automatic) |
| `feature/*` | New features | DEV (local) |
| `release/*` | Release stabilization | QA → PROD (via PR) |
| `hotfix/*` | Production fixes | PROD (via PR) |

---

## 6. GitOps Deployment Model

```
Developer          GitHub              CI/CD              ArgoCD/Flux         K8s Cluster
   │                  │                  │                    │                   │
   │─── push ────────►│                  │                    │                   │
   │                  │── trigger ──────►│                    │                   │
   │                  │                  │── build & test ───►│                   │
   │                  │                  │── push image ─────►│                   │
   │                  │◄─ update k8s/ ──│                    │                   │
   │                  │                  │                    │── detect change ─►│
   │                  │                  │                    │── sync manifests──►│
   │                  │                  │                    │                   │── deploy
   │                  │                  │                    │                   │
```

### Key Principles

1. **Git is the single source of truth** — all K8s manifests live in `k8s/`
2. **No `kubectl apply` in production** — all PROD changes go through PRs
3. **Immutable images** — tagged by Git SHA, never `latest` in QA/PROD
4. **Secrets are external** — K8s Secrets backed by Vault, never in Git

---

## 7. Configuration Management

### Resolution Order

The `ConfigLoader` applies configuration in this precedence (last wins):

```
1. application.properties          (classpath, base defaults)
2. application-{env}.properties    (classpath, environment overlay)
3. -Dconfig.file=/path/to/file     (external file override)
4. -Dkafka.bootstrap.servers=...   (system property override)
5. KAFKA_BOOTSTRAP_SERVERS=...     (environment variable override)
```

### Environment-Specific Config Strategy

| Property | DEV | QA | PROD |
|---|---|---|---|
| `bootstrap.servers` | `localhost:9092` | From ConfigMap | From ConfigMap |
| `security.protocol` | `PLAINTEXT` | `SASL_SSL` | `SASL_SSL` |
| `sasl.jaas.config` | — | From K8s Secret | From K8s Secret (Vault) |
| `acks` | `1` (default) | `all` | `all` |
| `enable.idempotence` | `false` (default) | `true` | `true` |
| `processing.guarantee` | — | `exactly_once_v2` | `exactly_once_v2` |

### Connecting to Confluent Cloud (Manual, DEV)

```bash
export KAFKA_BOOTSTRAP_SERVERS="pkc-xxxxx.us-east-1.aws.confluent.cloud:9092"
export KAFKA_SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username='<KEY>' password='<SECRET>';"
export SCHEMA_REGISTRY_URL="https://psrc-xxxxx.us-east-1.aws.confluent.cloud"
export SCHEMA_REGISTRY_USER_INFO="<SR_KEY>:<SR_SECRET>"

java -Dapp.env=dev -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar produce
```

---

## 8. PCI-DSS Compliance

### 8.1 Data Protection (Req 3)

Card numbers are **masked before producing** to Kafka. The `Payment` schema only stores `card_number_masked`:

```java
// PaymentProducer.java — masking happens BEFORE the message is built
String maskedCard = "****-****-****-" + last4Digits;
```

**Full card numbers (PAN) must NEVER appear in:**
- Kafka messages
- Log files
- Environment variables
- Configuration files

### 8.2 Encryption in Transit (Req 4)

All QA and PROD connections use `SASL_SSL`:

```properties
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
  username='${API_KEY}' \
  password='${API_SECRET}';
```

### 8.3 Network Segmentation (Req 1)

K8s `NetworkPolicy` restricts pod traffic to Confluent Cloud endpoints only:

```yaml
# k8s/base/networkpolicy.yaml
egress:
  - ports:
      - protocol: TCP
        port: 9092      # Kafka (SASL_SSL)
      - protocol: TCP
        port: 443       # Schema Registry (HTTPS)
```

### 8.4 Audit Logging (Req 10)

- `client.id` is set on all producers/consumers for audit trail
- Logback writes structured, rotated logs (90 days retention)
- K8s pod logs are forwarded to a centralized logging system

```xml
<!-- logback.xml — PCI-DSS compliant log retention -->
<maxHistory>90</maxHistory>
<totalSizeCap>2GB</totalSizeCap>
```

### 8.5 Secure Development (Req 6)

- CI runs Trivy vulnerability scanner on every build
- PRs require code review before merge
- PROD deployments require operations team approval
- Dependencies are pinned to specific versions in `pom.xml`

### 8.6 Change Management (Req 12)

| Environment | Change Process |
|---|---|
| DEV | Self-service, no approval |
| QA | Automated via CI/CD on `develop` merge |
| PROD | PR with PCI-DSS checklist, Ops approval required |

---

## 9. Developer Toolbox

### 9.1 Build & Development Tools

| Tool | Purpose | Install |
|---|---|---|
| **Maven** | Build, test, package | `brew install maven` / `sdk install maven` |
| **Jib** | Containerize without Docker daemon | Included in `pom.xml` plugin |
| **Avro Maven Plugin** | Generate Java classes from `.avsc` | Included in `pom.xml` plugin |
| **TopologyTestDriver** | Test KStreams topologies without a broker | `kafka-streams-test-utils` dependency |
| **Testcontainers** | Integration tests with real Kafka | `testcontainers/kafka` dependency |

#### Build Commands Reference

```bash
# Full build with tests
mvn clean verify

# Build without tests (fast)
mvn clean package -DskipTests

# Build only the kstreams module
mvn clean package -pl kstreams-app -am -DskipTests

# Generate Avro classes only
mvn generate-sources

# Build container image with Jib (no Docker needed)
mvn compile jib:build -pl producer-consumer-app

# Build container image to local Docker daemon
mvn compile jib:dockerBuild -pl producer-consumer-app
```

### 9.2 Confluent Cloud CLI

```bash
# Install
curl -sL https://cnfl.io/cli | sh

# Login
confluent login

# List environments
confluent environment list

# Select environment
confluent environment use env-xxxxx

# List clusters
confluent kafka cluster list

# Select cluster
confluent kafka cluster use lkc-xxxxx

# Create API key
confluent api-key create --resource lkc-xxxxx

# List topics
confluent kafka topic list

# Produce a test message
confluent kafka topic produce payments --parse-key --delimiter="|"
# Type: key1|{"transaction_id":"test","amount":100.00}

# Consume messages
confluent kafka topic consume payments --from-beginning --print-key

# Describe consumer group
confluent kafka consumer group lag describe payment-consumer-group
```

### 9.3 kcat (kafkacat) — Low-Level Kafka Tool

```bash
# Install
brew install kcat      # macOS
apt install kafkacat   # Debian/Ubuntu

# --- Local broker ---

# List topics and metadata
kcat -b localhost:9092 -L

# Produce messages
echo '{"transaction_id":"test-1","amount":50.00}' | \
  kcat -b localhost:9092 -t payments -P -K "|"

# Consume from beginning
kcat -b localhost:9092 -t payments -C -f 'Topic: %t | Partition: %p | Offset: %o | Key: %k | Value: %s\n'

# Consume last 5 messages
kcat -b localhost:9092 -t payments -C -o -5 -e

# --- Confluent Cloud ---

kcat -b pkc-xxxxx.us-east-1.aws.confluent.cloud:9092 \
     -X security.protocol=SASL_SSL \
     -X sasl.mechanism=PLAIN \
     -X sasl.username=<API_KEY> \
     -X sasl.password=<API_SECRET> \
     -t payments -C -o beginning -e
```

### 9.4 Kafka CLI Tools (from Confluent Platform)

```bash
# Download Confluent Platform (CLI tools only)
# https://www.confluent.io/installation/

# List topics
kafka-topics --bootstrap-server localhost:9092 --list

# Describe a topic
kafka-topics --bootstrap-server localhost:9092 --describe --topic payments

# Consumer groups
kafka-consumer-groups --bootstrap-server localhost:9092 --list
kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group payment-consumer-group

# Reset offsets (DEV only!)
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group payment-consumer-group \
  --topic payments \
  --reset-offsets --to-earliest --execute

# Performance test (producer)
kafka-producer-perf-test --topic payments \
  --num-records 10000 \
  --record-size 500 \
  --throughput 1000 \
  --producer-props bootstrap.servers=localhost:9092

# Performance test (consumer)
kafka-consumer-perf-test --bootstrap-server localhost:9092 \
  --topic payments \
  --messages 10000
```

### 9.5 Schema Registry Tools

```bash
# List all subjects
curl -s http://localhost:8081/subjects | jq .

# Get latest schema for a subject
curl -s http://localhost:8081/subjects/payments-value/versions/latest | jq .

# Register a new schema
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data @producer-consumer-app/src/main/avro/payment.avsc \
  http://localhost:8081/subjects/payments-value/versions

# Test schema compatibility
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data @producer-consumer-app/src/main/avro/payment.avsc \
  http://localhost:8081/compatibility/subjects/payments-value/versions/latest

# Confluent Cloud Schema Registry
curl -u "<SR_API_KEY>:<SR_API_SECRET>" \
  https://psrc-xxxxx.us-east-1.aws.confluent.cloud/subjects | jq .
```

### 9.6 Docker & Container Tools

```bash
# Start full local stack
cd docker && docker-compose up -d

# View logs
docker-compose logs -f broker
docker-compose logs -f kstreams

# Stop and clean up
docker-compose down -v

# Build images manually
docker build -f docker/Dockerfile.producer-consumer -t payment-app:local .
docker build -f docker/Dockerfile.kstreams -t fraud-detection:local .

# Run container locally
docker run --rm --network docker_default \
  -e APP_ENV=dev \
  -e KAFKA_BOOTSTRAP_SERVERS=broker:29092 \
  payment-app:local produce
```

### 9.7 Kubernetes Tools

```bash
# Apply dev overlay
kubectl apply -k k8s/overlays/dev/

# Check pod status
kubectl get pods -n confluent-apps-dev -w

# View logs
kubectl logs -n confluent-apps-dev -l app=fraud-detection -f --tail=100

# Exec into pod for debugging
kubectl exec -it -n confluent-apps-dev deployment/fraud-detection -- sh

# Port-forward JMX (for local monitoring)
kubectl port-forward -n confluent-apps-dev svc/fraud-detection 9101:9101

# Scale KStreams instances
kubectl scale deployment/fraud-detection -n confluent-apps-dev --replicas=3

# Restart deployment (rolling)
kubectl rollout restart deployment/fraud-detection -n confluent-apps-dev

# Check resource usage
kubectl top pods -n confluent-apps-dev
```

### 9.8 Make — Unified Build Interface

All common commands wrapped in a single `Makefile`:

```bash
make help           # Show all available targets
make build          # mvn clean package -DskipTests
make test           # mvn verify
make ci             # Full CI pipeline (build, test, scan)
make docker-build   # Build Docker images for both apps
make local-up       # docker compose up (broker + SR)
make topics         # Create Kafka topics
make kind-create    # Create local K8s cluster (kind)
make k8s-dev        # kubectl apply -k k8s/overlays/dev
make diagnose       # Run full diagnostics
make load-test      # k6 load test
```

See `Makefile` at the repository root for the full list.

### 9.9 Act — Local GitHub Actions

Run CI/CD pipelines on your laptop before pushing:

```bash
# Install: brew install act
# Repo:    https://github.com/nektos/act

act push --workflows .github/workflows/ci.yaml          # Run full CI
act push --workflows .github/workflows/ci.yaml --job build  # Run one job
act --list --workflows .github/workflows/ci.yaml        # List jobs
act push --dryrun                                        # Dry-run
```

### 9.10 kind — Kubernetes in Docker

Disposable K8s clusters for local testing:

```bash
# Install: brew install kind
# Repo:    https://github.com/kubernetes-sigs/kind

kind create cluster --name kafka-dev --config kind-cluster.yaml
kind load docker-image payment-app:workshop --name kafka-dev  # No registry push!
kubectl apply -k k8s/overlays/dev/
kind delete cluster --name kafka-dev
```

### 9.11 Helm — Kubernetes Package Manager

Parameterized deployments with rollback support:

```bash
# Install: brew install helm
# Repo:    https://github.com/helm/helm

helm install payment-app ./helm/payment-app --values helm/payment-app/values-dev.yaml -n confluent-apps
helm upgrade payment-app ./helm/payment-app --set image.tag=v1.1.0
helm rollback payment-app 1
helm template payment-app ./helm/payment-app --values helm/payment-app/values-prod.yaml
```

### 9.12 k6 — Load Testing

Developer-friendly load testing with CI integration:

```bash
# Install: brew install k6
# Repo:    https://github.com/grafana/k6

k6 run tests/load/payment-producer-test.js
k6 run --vus 50 --duration 2m tests/load/payment-producer-test.js
k6 run --out json=results.json tests/load/payment-producer-test.js
```

### 9.13 ngrok — Secure Tunnels

Expose local services for webhook testing and demos:

```bash
# Install: brew install ngrok
# Website: https://ngrok.com

ngrok http 8080                # Public URL → localhost:8080
# Inspect traffic: http://127.0.0.1:4040
```

> For full tool documentation with examples, role mapping, and workshop integration,
> see [docs/workshop/TOOLS.md](docs/workshop/TOOLS.md).

---

## 10. Troubleshooting & Diagnostics

### 10.1 Quick Diagnostics Script

Use the built-in diagnostics tool:

```bash
# Run all checks
./scripts/diagnose.sh full

# Or run individual checks:
./scripts/diagnose.sh connectivity       # Test broker reachability
./scripts/diagnose.sh consumer-lag       # Check consumer group lag
./scripts/diagnose.sh topic-inspect      # Inspect topic metadata
./scripts/diagnose.sh kstreams-state     # KStreams internal state
./scripts/diagnose.sh schema-check       # Schema Registry health
./scripts/diagnose.sh k8s-status         # K8s pod status + logs
```

### 10.2 Common Issues & Fixes

#### Connection Refused / Timeout

```
org.apache.kafka.common.errors.TimeoutException:
  Topic payments not present in metadata after 60000 ms.
```

**Diagnosis:**
```bash
# Check broker reachability
kcat -b $KAFKA_BOOTSTRAP_SERVERS -L 2>&1 | head -5

# Check security config
# If using Confluent Cloud, ensure SASL_SSL is configured
echo $KAFKA_SASL_JAAS_CONFIG | head -c 50
```

**Fixes:**
- Verify `bootstrap.servers` is correct
- Ensure `security.protocol=SASL_SSL` for Confluent Cloud
- Check API key is valid and not expired
- Verify network connectivity (firewalls, VPN, NetworkPolicy)

---

#### Consumer Lag Growing

```bash
# Check lag
kafka-consumer-groups --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
  --describe --group payment-consumer-group
```

```
GROUP                   TOPIC      PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
payment-consumer-group  payments   0          1000            5000            4000
payment-consumer-group  payments   1          1200            4800            3600
```

**Fixes:**
- Increase consumer instances: `kubectl scale deployment/payment-consumer --replicas=6`
- Increase topic partitions (consumers cannot exceed partition count)
- Check for slow processing in the consumer loop
- Verify `max.poll.records` and `max.poll.interval.ms` settings

---

#### KStreams — Rebalancing Loop

```
WARN  StreamThread - State transition: RUNNING -> PARTITIONS_REVOKED
INFO  StreamThread - State transition: PARTITIONS_REVOKED -> PARTITIONS_ASSIGNED
```

**Diagnosis:**
```bash
# Check if instances are crashing
kubectl get pods -n confluent-apps -l app=fraud-detection -w

# Check resource limits
kubectl describe pod -n confluent-apps -l app=fraud-detection | grep -A5 "Limits"
```

**Fixes:**
- Increase `session.timeout.ms` (default 45s → 120s for heavy state stores)
- Increase memory limits in K8s deployment
- Ensure `num.standby.replicas=1` for faster failover
- Check for OOMKilled events: `kubectl get events -n confluent-apps | grep OOM`

---

#### Schema Compatibility Error

```
io.confluent.kafka.schemaregistry.client.rest.exceptions.RestClientException:
  Schema being registered is incompatible with an earlier schema; error code: 409
```

**Diagnosis:**
```bash
# Check current compatibility level
curl -s http://localhost:8081/config/payments-value | jq .

# Check registered schemas
curl -s http://localhost:8081/subjects/payments-value/versions | jq .
```

**Fixes:**
- Review Avro schema evolution rules (no required field removal, no type changes)
- Use `BACKWARD` compatibility (default) — new schema can read old data
- Test compatibility before deploying:
  ```bash
  curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data @producer-consumer-app/src/main/avro/payment.avsc \
    http://localhost:8081/compatibility/subjects/payments-value/versions/latest
  ```

---

#### Serialization / Deserialization Errors

```
org.apache.kafka.common.errors.SerializationException:
  Error deserializing Avro message
```

**Diagnosis:**
```bash
# Consume raw bytes to inspect the message
kcat -b localhost:9092 -t payments -C -f '%s\n' -o beginning -c 1 | xxd | head

# Check if messages are Avro-encoded (should start with magic byte 0x00)
# Byte 0: 0x00 (magic byte)
# Bytes 1-4: schema ID (big-endian int)
```

**Fixes:**
- Ensure producer and consumer use the same serializer/deserializer
- Verify Schema Registry URL is correct
- Check that the topic was not previously used with a different serialization format
- For mixed formats, use `auto.register.schemas=false` in production

---

#### Exactly-Once Processing Failures

```
org.apache.kafka.common.errors.ProducerFencedException:
  Producer attempted an operation with an old epoch
```

**Fixes:**
- This is normal during rebalances — the fenced producer will shut down and rejoin
- Ensure `processing.guarantee=exactly_once_v2` in KStreams config
- Ensure `enable.idempotence=true` on standalone producers
- Check for multiple instances with the same `transactional.id`

---

### 10.3 JMX Monitoring

```bash
# Enable JMX on the Java app
java -Dcom.sun.management.jmxremote \
     -Dcom.sun.management.jmxremote.port=9101 \
     -Dcom.sun.management.jmxremote.authenticate=false \
     -Dcom.sun.management.jmxremote.ssl=false \
     -jar kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar
```

Key JMX metrics to monitor:

| Bean | Metric | Alert Threshold |
|---|---|---|
| `kafka.consumer` | `records-lag-max` | > 10000 |
| `kafka.consumer` | `records-consumed-rate` | < expected throughput |
| `kafka.producer` | `record-error-rate` | > 0 |
| `kafka.producer` | `record-send-rate` | < expected throughput |
| `kafka.streams` | `alive-stream-threads` | < configured threads |
| `kafka.streams` | `commit-latency-avg` | > 500ms |
| `kafka.streams` | `process-rate` | < expected throughput |

### 10.4 Log Levels for Debugging

```bash
# Temporarily enable DEBUG logging for Kafka clients
java -Dlogback.configurationFile=logback-debug.xml -jar app.jar

# Or set via system property
java -Dlogging.level.org.apache.kafka=DEBUG -jar app.jar
```

Key loggers for troubleshooting:

| Logger | Use Case |
|---|---|
| `org.apache.kafka.clients.consumer` | Consumer issues, rebalances |
| `org.apache.kafka.clients.producer` | Producer retries, failures |
| `org.apache.kafka.streams` | Streams state transitions, rebalances |
| `org.apache.kafka.clients.NetworkClient` | Connection issues |
| `io.confluent.kafka.serializers` | Serialization / Schema Registry |

---

## 11. Appendix

### 11.1 Environment Variable Reference

| Variable | Description | Required in |
|---|---|---|
| `APP_ENV` | Target environment (`dev`, `qa`, `prod`) | All |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker endpoint | QA, PROD |
| `KAFKA_SECURITY_PROTOCOL` | Security protocol (`SASL_SSL`) | QA, PROD |
| `KAFKA_SASL_MECHANISM` | SASL mechanism (`PLAIN`) | QA, PROD |
| `KAFKA_SASL_JAAS_CONFIG` | JAAS config with credentials | QA, PROD |
| `SCHEMA_REGISTRY_URL` | Schema Registry endpoint | QA, PROD |
| `SCHEMA_REGISTRY_USER_INFO` | SR credentials (`key:secret`) | QA, PROD |
| `KAFKA_CLIENT_ID` | Client identifier for audit | PROD |
| `KAFKA_GROUP_ID` | Consumer group ID | All |

### 11.2 Topic Configuration Reference

| Topic | Partitions | Retention | Cleanup | Purpose |
|---|---|---|---|---|
| `payments` | 6 | 7 days | delete | Raw payment events |
| `fraud-alerts` | 6 | 30 days | delete | Flagged transactions |
| `approved-payments` | 6 | 7 days | delete | Approved transactions |

### 11.3 Useful Links

- [Confluent Cloud Documentation](https://docs.confluent.io/cloud/current/)
- [Kafka Client Configuration Reference](https://kafka.apache.org/documentation/#configuration)
- [Kafka Streams Developer Guide](https://kafka.apache.org/documentation/streams/)
- [Schema Registry API Reference](https://docs.confluent.io/platform/current/schema-registry/develop/api.html)
- [PCI-DSS v4.0 Requirements](https://www.pcisecuritystandards.org/)
- [Confluent CLI Reference](https://docs.confluent.io/confluent-cli/current/)
