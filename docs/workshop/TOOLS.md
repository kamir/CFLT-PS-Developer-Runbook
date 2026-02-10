# Developer Toolbox — Complete Reference

> Tools for developing, testing, deploying, and operating Kafka applications on Confluent Cloud.
> Organized by lifecycle stage and workshop level.

---

## Table of Contents

1. [Tool Landscape](#1-tool-landscape)
2. [Build & Automation](#2-build--automation)
   - [2.1 Make](#21-make)
   - [2.2 Act — Local GitHub Actions](#22-act--local-github-actions)
3. [Confluent & Kafka CLI](#3-confluent--kafka-cli)
   - [3.1 Confluent CLI](#31-confluent-cli)
   - [3.2 Kafka CLI Tools](#32-kafka-cli-tools)
   - [3.3 kcat (kafkacat)](#33-kcat-kafkacat)
4. [Kubernetes & Infrastructure](#4-kubernetes--infrastructure)
   - [4.1 kind — Kubernetes in Docker](#41-kind--kubernetes-in-docker)
   - [4.2 Helm](#42-helm)
5. [Testing & Traffic](#5-testing--traffic)
   - [5.1 k6 — Load Testing](#51-k6--load-testing)
   - [5.2 ngrok — Secure Tunnels](#52-ngrok--secure-tunnels)
   - [5.3 Shadow Traffic](#53-shadow-traffic)
6. [Workshop Level Map](#6-workshop-level-map)

---

## 1. Tool Landscape

```
                           APPLICATION LIFECYCLE
   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │  DESIGN  │──>│  BUILD   │──>│  TEST    │──>│  DEPLOY  │──>│  OPERATE │
   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
        │              │              │               │              │
        │         ┌────┴────┐    ┌────┴────┐    ┌────┴────┐    ┌───┴────┐
        │         │  Make   │    │  k6     │    │  Helm   │    │ kcat   │
        │         │  Maven  │    │  kcat   │    │  kind   │    │Confluent│
        │         │  Act    │    │  ngrok  │    │  Act    │    │  CLI   │
        │         └─────────┘    │ Shadow  │    └─────────┘    │ Kafka  │
        │                        │ Traffic │                    │  CLI   │
        │                        └─────────┘                    └────────┘

   Level 101: Blocks 1–6 (current workshop — foundational skills)
   Level 201: Tool introduction — what each tool does, when to use it
   Level 301: Deep dive — integrate tools into team workflows and planning
   Level 401: Engineering — RocksDB tuning, performance, production hardening
```

### Who Uses What?

| Tool | Developer | DevOps / SRE | Tech Lead | Ops Team |
|---|---|---|---|---|
| **Make** | Daily builds | CI scripting | Standardization | — |
| **Act** | Test CI locally | Pipeline dev | PR review | — |
| **Confluent CLI** | Topic mgmt | Cluster mgmt | Env planning | Monitoring |
| **Kafka CLI** | Debug topics | Offset mgmt | Capacity review | Incident response |
| **kcat** | Message inspection | Connectivity test | — | Incident triage |
| **kind** | Local K8s dev | Manifest testing | Architecture PoC | — |
| **Helm** | App deployment | Chart mgmt | Release planning | PROD deploy |
| **k6** | Load test code | Perf baselines | SLA validation | Stress tests |
| **ngrok** | Webhook dev | Tunnel testing | Demo/PoC | — |
| **Shadow Traffic** | — | Traffic mirroring | Risk assessment | Canary validation |

---

## 2. Build & Automation

### 2.1 Make

> **Unified command interface for the entire project lifecycle.**

| | |
|---|---|
| **What** | GNU Make — task runner using `Makefile` rules |
| **Why** | One consistent `make <target>` interface across build, test, Docker, K8s, and deploy. No need to remember 20 different commands. |
| **Repo** | [https://www.gnu.org/software/make/](https://www.gnu.org/software/make/) |
| **Install** | Pre-installed on Linux/macOS. Windows: `choco install make` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | `make build`, `make test`, `make run` — zero mental overhead |
| **DevOps** | CI pipelines call `make ci` — same commands locally and in CI |
| **Tech Lead** | Standardizes workflows across all team members |
| **New Joiner** | `make help` shows every available command — instant onboarding |

#### Example: Project Makefile

```makefile
# See the full Makefile at the repository root
make help          # Show all available targets
make build         # mvn clean package -DskipTests
make test          # mvn verify
make docker-build  # Build both Docker images
make local-up      # docker compose up (broker + SR + apps)
make local-down    # docker compose down -v
make topics        # Create Kafka topics
make k8s-dev       # kubectl apply -k k8s/overlays/dev
make diagnose      # Run full diagnostics
make ci            # Full CI: clean, build, test, scan
make workshop      # Run workshop validation (all blocks)
```

#### Integration Point

```bash
# Instead of remembering:
#   cd docker && docker compose up -d broker schema-registry && cd ..
#   ./scripts/create-topics.sh local
#   mvn clean package -DskipTests

# Just run:
make local-up topics build
```

---

### 2.2 Act — Local GitHub Actions

> **Run your GitHub Actions workflows locally before pushing.**

| | |
|---|---|
| **What** | `act` — runs GitHub Actions workflows on your machine using Docker |
| **Why** | Catch CI failures before pushing. No more "fix CI" commits. |
| **Repo** | [https://github.com/nektos/act](https://github.com/nektos/act) |
| **Website** | [https://nektosact.com](https://nektosact.com) |
| **Install** | `brew install act` / `curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh \| bash` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Test CI pipeline locally — instant feedback, no push/wait cycle |
| **DevOps** | Develop and debug workflow YAML without trial-and-error pushes |
| **Tech Lead** | Enforce that CI passes locally before PR review |

#### Example

```bash
# Run the CI workflow locally
act push --workflows .github/workflows/ci.yaml

# Run only the build job
act push --workflows .github/workflows/ci.yaml --job build

# Run with specific event data
act push --workflows .github/workflows/ci.yaml \
  --eventpath .github/test-events/push-develop.json

# List all available workflows and jobs
act --list

# Dry-run (show what would happen)
act push --workflows .github/workflows/ci.yaml --dryrun
```

#### Typical Workflow

```
Developer writes code
      │
      ├──> make ci           (local build + test)
      ├──> act push          (local CI pipeline simulation)
      │       ├── build job    [PASS]
      │       ├── docker job   [PASS]
      │       └── security job [PASS]
      │
      └──> git push          (confident that CI will pass)
```

#### Event File Example

```json
// .github/test-events/push-develop.json
{
  "ref": "refs/heads/develop",
  "repository": {
    "default_branch": "main"
  }
}
```

---

## 3. Confluent & Kafka CLI

### 3.1 Confluent CLI

> **The single CLI for managing all Confluent Cloud resources.**

| | |
|---|---|
| **What** | Official Confluent CLI — manage environments, clusters, topics, API keys, connectors, and more |
| **Why** | Scriptable cloud management. Create environments, provision clusters, and manage schemas from the terminal. |
| **Repo** | Proprietary (closed-source binary) |
| **Website** | [https://docs.confluent.io/confluent-cli/current/overview.html](https://docs.confluent.io/confluent-cli/current/overview.html) |
| **Install** | `brew install confluentinc/tap/cli` / `curl -sL https://cnfl.io/cli \| sh` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Create topics, produce/consume test messages, inspect schemas |
| **DevOps** | Script environment provisioning, API key rotation, cluster setup |
| **Tech Lead** | Review cluster configuration, plan capacity |
| **Ops Team** | Monitor consumer lag, manage ACLs, audit access |

#### Example: Daily Developer Workflow

```bash
# Login (one-time)
confluent login

# Select environment and cluster
confluent environment use env-abc123
confluent kafka cluster use lkc-def456

# List topics
confluent kafka topic list

# Produce a test message
echo '{"transaction_id":"test-001","amount":42.50}' | \
  confluent kafka topic produce payments --parse-key --delimiter="|"

# Consume messages
confluent kafka topic consume payments --from-beginning --print-key

# Check consumer group lag
confluent kafka consumer group lag describe payment-consumer-group

# Create a new API key (for a service account)
confluent api-key create --resource lkc-def456 \
  --service-account sa-12345 \
  --description "QA pipeline key"

# Schema Registry — list subjects
confluent schema-registry subject list

# Describe a schema
confluent schema-registry subject describe payments-value
```

#### Script: Rotate API Keys

```bash
#!/usr/bin/env bash
# Rotate Kafka API key for a service account
OLD_KEY="$1"
CLUSTER="$2"
SA="$3"

echo "Creating new API key..."
NEW_KEY_JSON=$(confluent api-key create --resource "$CLUSTER" \
  --service-account "$SA" -o json)
NEW_KEY=$(echo "$NEW_KEY_JSON" | jq -r '.api_key')

echo "New key: $NEW_KEY — update K8s Secret, then delete old key."
echo "To delete old key: confluent api-key delete $OLD_KEY"
```

---

### 3.2 Kafka CLI Tools

> **The classic Apache Kafka command-line tools for topic and consumer group management.**

| | |
|---|---|
| **What** | Shell scripts shipped with Apache Kafka / Confluent Platform: `kafka-topics`, `kafka-consumer-groups`, `kafka-configs`, `kafka-producer-perf-test`, `kafka-consumer-perf-test` |
| **Why** | Direct, low-level control over topics, consumer groups, offsets, and configuration. Essential for debugging and performance testing. |
| **Repo** | [https://github.com/apache/kafka](https://github.com/apache/kafka) |
| **Website** | [https://kafka.apache.org/documentation/#operations](https://kafka.apache.org/documentation/#operations) |
| **Install** | Bundled with Confluent Platform: [https://www.confluent.io/installation/](https://www.confluent.io/installation/) |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Describe topics, check partition distribution, test throughput |
| **DevOps** | Reset offsets, reassign partitions, tune topic configs |
| **Ops Team** | Incident response — inspect ISR, under-replicated partitions |

#### Example: Operations Cheat Sheet

```bash
# ---------- Topic management ----------

# List all topics
kafka-topics --bootstrap-server localhost:9092 --list

# Describe topic (partitions, replicas, ISR)
kafka-topics --bootstrap-server localhost:9092 --describe --topic payments

# Increase partitions (irreversible!)
kafka-topics --bootstrap-server localhost:9092 --alter \
  --topic payments --partitions 12

# ---------- Consumer group management ----------

# List consumer groups
kafka-consumer-groups --bootstrap-server localhost:9092 --list

# Describe group (shows lag per partition)
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group payment-consumer-group

# Reset offsets to earliest (DEV/QA only!)
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group payment-consumer-group --topic payments \
  --reset-offsets --to-earliest --execute

# Reset to specific offset
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group payment-consumer-group --topic payments:0 \
  --reset-offsets --to-offset 1000 --execute

# ---------- Performance testing ----------

# Producer throughput test
kafka-producer-perf-test \
  --topic payments \
  --num-records 100000 \
  --record-size 512 \
  --throughput 10000 \
  --producer-props bootstrap.servers=localhost:9092

# Consumer throughput test
kafka-consumer-perf-test \
  --bootstrap-server localhost:9092 \
  --topic payments \
  --messages 100000

# ---------- Config management ----------

# Describe topic-level configs
kafka-configs --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name payments --describe

# Set retention to 24 hours
kafka-configs --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name payments \
  --alter --add-config retention.ms=86400000
```

---

### 3.3 kcat (kafkacat)

> **The netcat for Apache Kafka — fast, flexible, scriptable.**

| | |
|---|---|
| **What** | Generic Kafka producer, consumer, and metadata inspector. Lightweight C-based CLI. |
| **Why** | Faster than Java-based tools for quick inspection. Supports advanced formatting, JSON output, and Avro deserialization. |
| **Repo** | [https://github.com/edenhill/kcat](https://github.com/edenhill/kcat) |
| **Website** | [https://github.com/edenhill/kcat#readme](https://github.com/edenhill/kcat#readme) |
| **Install** | `brew install kcat` / `apt install kafkacat` / `conda install -c conda-forge kcat` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Quick message inspection, produce test data, verify formats |
| **DevOps** | Connectivity checks, metadata inspection, scripted data extraction |
| **Ops Team** | Rapid incident triage — read specific offsets, check partition leaders |

#### Example: Power User Commands

```bash
# ---------- Metadata ----------

# Full cluster metadata (brokers, topics, partitions)
kcat -b localhost:9092 -L

# Topic-specific metadata
kcat -b localhost:9092 -L -t payments

# JSON metadata output (pipe to jq)
kcat -b localhost:9092 -L -J | jq '.topics[] | .topic'

# ---------- Consume ----------

# Read 5 messages from beginning with formatted output
kcat -b localhost:9092 -t payments -C \
  -f '\n--- Message ---\nPartition: %p\nOffset:    %o\nTimestamp: %T\nKey:       %k\nHeaders:   %h\nValue:     %s\n' \
  -o beginning -c 5

# Read messages from specific partition and offset
kcat -b localhost:9092 -t payments -C -p 2 -o 100 -c 1

# Read only the last message from each partition
kcat -b localhost:9092 -t payments -C -o -1 -e

# Output as JSON (useful for piping)
kcat -b localhost:9092 -t payments -C -J -o beginning -c 3 | jq .

# ---------- Produce ----------

# Produce from stdin (key|value)
echo "txn-001|{\"transaction_id\":\"txn-001\",\"amount\":150.00}" | \
  kcat -b localhost:9092 -t payments -P -K "|"

# Produce from a file
kcat -b localhost:9092 -t payments -P -l test-data/payments.jsonl

# ---------- Confluent Cloud ----------

kcat -b pkc-xxx.us-east-1.aws.confluent.cloud:9092 \
  -X security.protocol=SASL_SSL \
  -X sasl.mechanism=PLAIN \
  -X sasl.username="$CCLOUD_API_KEY" \
  -X sasl.password="$CCLOUD_API_SECRET" \
  -t payments -C -o beginning -c 5 -e
```

---

## 4. Kubernetes & Infrastructure

### 4.1 kind — Kubernetes in Docker

> **Disposable Kubernetes clusters on your laptop in 30 seconds.**

| | |
|---|---|
| **What** | kind (Kubernetes IN Docker) — runs K8s clusters using Docker containers as nodes |
| **Why** | Test K8s manifests, Helm charts, NetworkPolicies, and deployments locally without a cloud cluster. Disposable and fast. |
| **Repo** | [https://github.com/kubernetes-sigs/kind](https://github.com/kubernetes-sigs/kind) |
| **Website** | [https://kind.sigs.k8s.io](https://kind.sigs.k8s.io) |
| **Install** | `brew install kind` / `go install sigs.k8s.io/kind@latest` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Test K8s deployments locally before pushing to shared clusters |
| **DevOps** | Validate Kustomize overlays, Helm charts, and RBAC policies |
| **Tech Lead** | PoC new architectures without cloud costs |

#### Example: Local K8s Testing

```bash
# Create a cluster with custom config
kind create cluster --name kafka-dev --config kind-cluster.yaml

# Verify
kubectl cluster-info --context kind-kafka-dev
kubectl get nodes

# Load locally built Docker images into kind (no registry push!)
kind load docker-image payment-app:workshop --name kafka-dev
kind load docker-image fraud-detection:workshop --name kafka-dev

# Apply our Kustomize overlay
kubectl apply -k k8s/overlays/dev/

# Test NetworkPolicy
kubectl get networkpolicy -n confluent-apps-dev

# Check pod status
kubectl get pods -n confluent-apps-dev -w

# Clean up — destroy the entire cluster
kind delete cluster --name kafka-dev
```

#### kind Cluster Config

```yaml
# kind-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
networking:
  # Enable NetworkPolicy support (Calico)
  disableDefaultCNI: false
```

#### Integration with Makefile

```bash
make kind-create      # Create kind cluster
make kind-load        # Load Docker images into kind
make kind-deploy-dev  # Apply dev overlay
make kind-destroy     # Tear down cluster
```

---

### 4.2 Helm

> **The package manager for Kubernetes.**

| | |
|---|---|
| **What** | Helm — templated K8s manifests packaged as reusable "charts" |
| **Why** | Parameterize deployments across environments. Share and version your application packaging. Use community charts for infrastructure (Kafka, monitoring, etc.). |
| **Repo** | [https://github.com/helm/helm](https://github.com/helm/helm) |
| **Website** | [https://helm.sh](https://helm.sh) |
| **Install** | `brew install helm` / `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | `helm install` to deploy apps with env-specific values |
| **DevOps** | Create and maintain reusable charts, manage chart versions |
| **Tech Lead** | Standardize deployment packaging, enforce config structure |
| **Ops Team** | `helm rollback` for instant production rollback |

#### Example: Application Helm Chart

```bash
# ---------- Using community charts ----------

# Add Confluent Helm repo
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update

# Install Confluent for Kubernetes operator
helm install confluent-operator confluentinc/confluent-for-kubernetes \
  --namespace confluent --create-namespace

# ---------- Our application chart ----------

# Install with dev values
helm install payment-app ./helm/payment-app \
  --namespace confluent-apps-dev \
  --values helm/payment-app/values-dev.yaml

# Upgrade with new image tag
helm upgrade payment-app ./helm/payment-app \
  --namespace confluent-apps-dev \
  --set image.tag=abc123def

# Rollback to previous release
helm rollback payment-app 1 --namespace confluent-apps-dev

# Show diff before upgrade (helm-diff plugin)
helm diff upgrade payment-app ./helm/payment-app \
  --values helm/payment-app/values-qa.yaml

# Template rendering (dry-run, see what K8s manifests are generated)
helm template payment-app ./helm/payment-app \
  --values helm/payment-app/values-prod.yaml
```

#### Helm Values per Environment

```yaml
# helm/payment-app/values-dev.yaml
replicaCount: 1
image:
  tag: "latest"
resources:
  requests:
    cpu: 100m
    memory: 256Mi

# helm/payment-app/values-prod.yaml
replicaCount: 4
image:
  tag: "v1.0.0"    # pinned!
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

---

## 5. Testing & Traffic

### 5.1 k6 — Load Testing

> **Modern load testing with JavaScript. Developer-friendly, CI-integrated.**

| | |
|---|---|
| **What** | k6 — open-source load testing tool. Write tests in JavaScript, run from CLI, get real-time metrics. |
| **Why** | Validate throughput, latency, and error rates under load. Ensure your Kafka pipeline handles peak traffic before PROD. |
| **Repo** | [https://github.com/grafana/k6](https://github.com/grafana/k6) |
| **Website** | [https://k6.io](https://k6.io) |
| **Install** | `brew install k6` / `apt install k6` / Docker: `grafana/k6` |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Write load tests alongside application code |
| **DevOps** | Integrate load tests into CI/CD pipelines |
| **Tech Lead** | Define SLAs and validate them with automated tests |
| **Ops Team** | Stress test before production releases |

#### Example: Load Test for Payment Producer

```javascript
// tests/load/payment-producer-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const latency = new Trend('payment_latency');

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // ramp up to 10 VUs
    { duration: '1m',  target: 50 },   // ramp up to 50 VUs
    { duration: '2m',  target: 50 },   // sustain 50 VUs
    { duration: '30s', target: 0 },    // ramp down
  ],
  thresholds: {
    errors: ['rate<0.01'],              // <1% error rate
    payment_latency: ['p(95)<500'],     // 95th percentile < 500ms
  },
};

export default function () {
  const payload = JSON.stringify({
    transaction_id: `k6-txn-${__VU}-${__ITER}`,
    card_number_masked: '****-****-****-1234',
    amount: Math.random() * 1000,
    currency: 'USD',
    merchant_id: 'MERCH-001',
    timestamp: Date.now(),
    status: 'PENDING',
    region: 'US-EAST',
  });

  const res = http.post('http://localhost:8080/api/payments', payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'status is 202': (r) => r.status === 202,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  errorRate.add(res.status !== 202);
  latency.add(res.timings.duration);

  sleep(0.1);
}
```

```bash
# Run the load test
k6 run tests/load/payment-producer-test.js

# Run with custom VUs and duration
k6 run --vus 100 --duration 5m tests/load/payment-producer-test.js

# Output results to JSON for analysis
k6 run --out json=results.json tests/load/payment-producer-test.js

# Run in CI (exit code 1 if thresholds fail)
k6 run --quiet tests/load/payment-producer-test.js || exit 1
```

---

### 5.2 ngrok — Secure Tunnels

> **Expose your local services to the internet — instant public URL.**

| | |
|---|---|
| **What** | ngrok — secure tunnels to localhost. Get a public HTTPS URL pointing to your local service. |
| **Why** | Test webhooks, share your local dev environment for demos, debug external integrations without deploying. |
| **Repo** | Proprietary (free tier available) |
| **Website** | [https://ngrok.com](https://ngrok.com) |
| **Install** | `brew install ngrok` / `snap install ngrok` / [download](https://ngrok.com/download) |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Test webhook callbacks (e.g., payment confirmations) against local code |
| **DevOps** | Quick PoC for external integrations without full deployment |
| **Tech Lead** | Live demos from a local laptop |

#### Example: Expose Local Kafka REST Proxy

```bash
# Expose local REST Proxy (or your custom API) to the internet
ngrok http 8082

# Output:
# Forwarding  https://abc123.ngrok-free.app -> http://localhost:8082

# Now external services can POST to:
# https://abc123.ngrok-free.app/topics/payments

# Expose with custom subdomain (paid plan)
ngrok http 8082 --domain=payment-dev.ngrok-free.app

# Inspect traffic in ngrok's web UI
# Open http://127.0.0.1:4040 in your browser
```

#### Use Case: Webhook Development

```
External Payment       ngrok tunnel         Your Laptop
  Gateway                                   (localhost:8080)
     │                    │                       │
     │── POST /webhook ──>│── forward ──────────>│
     │                    │                       │── process event
     │                    │                       │── produce to Kafka
     │<── 200 OK ────────│<── response ─────────│
```

```bash
# Start your local webhook listener
java -Dapp.env=dev -jar producer-consumer-app/target/*.jar webhook-mode

# In another terminal, expose it
ngrok http 8080

# Copy the ngrok URL and configure it in the external payment gateway
# e.g., https://abc123.ngrok-free.app/webhook/payment
```

---

### 5.3 Shadow Traffic

> **Mirror production traffic to a test environment without affecting users.**

| | |
|---|---|
| **What** | Shadow traffic (traffic mirroring / dark launching) — duplicate live requests to a secondary system for validation. |
| **Why** | Test new code against real production traffic patterns without any risk to production users. Validate before cutover. |
| **Approach** | Implemented via Istio traffic mirroring, Kafka MirrorMaker 2, or application-level cloning. |
| **Reference** | [Istio Traffic Mirroring](https://istio.io/latest/docs/tasks/traffic-management/mirroring/) / [Confluent Cluster Linking](https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/) |

#### Who Benefits

| Role | Value |
|---|---|
| **Developer** | Validate new topology logic against real traffic shapes |
| **DevOps** | Compare resource consumption between old and new versions |
| **Tech Lead** | Risk-free validation of major refactors |
| **Ops Team** | Canary validation before production cutover |

#### Approach 1: Kafka Topic Mirroring (Confluent Cluster Linking)

```bash
# Mirror the 'payments' topic from PROD cluster to QA cluster
confluent kafka mirror create payments \
  --source-cluster lkc-prod-123 \
  --cluster lkc-qa-456 \
  --link prod-to-qa-link

# Your QA KStreams app processes the mirrored data
# Compare output: PROD fraud-alerts vs. QA fraud-alerts
```

```
PROD Cluster                QA Cluster
┌──────────────┐            ┌──────────────┐
│   payments   │───mirror──>│   payments   │
│              │            │              │
│ fraud-alerts │            │ fraud-alerts │ <── compare
│   (v1.0)     │            │   (v1.1)     │     results
└──────────────┘            └──────────────┘
```

#### Approach 2: Istio Service Mesh Mirroring

```yaml
# istio-mirror.yaml — mirror 100% of traffic to canary
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: payment-api
spec:
  hosts:
    - payment-api
  http:
    - route:
        - destination:
            host: payment-api
            subset: stable
          weight: 100
      mirror:
        host: payment-api
        subset: canary
      mirrorPercentage:
        value: 100.0
```

#### Approach 3: Application-Level Shadow (Simple)

```java
// In your API gateway or proxy:
CompletableFuture.runAsync(() -> {
    // Fire-and-forget to shadow environment
    shadowClient.forward(request);
});

// Primary path continues normally
return primaryService.process(request);
```

---

## 6. Workshop Level Map

### How Tools Map to Workshop Levels

| Tool | Level 101 (Blocks 1–6) | Level 201 | Level 301 | Level 401 |
|---|---|---|---|---|
| **Make** | — | Introduce Makefile | CI integration, custom targets | — |
| **Act** | — | Run CI locally | Develop custom workflows | — |
| **Confluent CLI** | Mentioned | Hands-on setup | Script environments, automate key rotation | — |
| **Kafka CLI** | Mentioned | Topic ops, groups | Perf testing, offset management | Partition tuning |
| **kcat** | Block 1, 6 | Advanced formats | Scripted data validation | — |
| **kind** | — | Create local cluster | Full K8s testing pipeline | NetworkPolicy audit |
| **Helm** | — | Install apps | Create custom charts | Chart security hardening |
| **k6** | — | First load test | CI-integrated perf gates | Throughput tuning |
| **ngrok** | — | Expose local API | Webhook integration testing | — |
| **Shadow Traffic** | — | Concept intro | Design mirroring strategy | Production traffic replay |

### Level Progression

```
Level 101 — "Sich die Sporen verdienen"
  You can build, test, and run Kafka apps locally.

Level 201 — "Das Werkzeug kennen"
  You know every tool in the box and when to reach for it.

Level 301 — "Die Werkstatt meistern"
  You integrate tools into team workflows, CI/CD, and release planning.

Level 401 — "Die Kunst der Optimierung"
  You tune RocksDB, optimize throughput, and harden for production.
```
