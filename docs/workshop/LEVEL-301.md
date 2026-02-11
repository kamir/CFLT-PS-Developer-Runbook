# Level 301 — Master the Workshop

> *Master the workshop.*
> Full-day session (6h) — integrating tools into team workflows, CI/CD, and release planning.

---

## Prerequisites

- Level 101 complete (Master Badge — all 6 Badges)
- Level 201 complete (Tool Master — all 4 tool Badges)
- Access to a Confluent Cloud environment (DEV or sandbox)

---

## Schedule

| Time | Block | Topic | Badge |
|---|---|---|---|
| 09:00 – 09:15 | Opening | Level 301 objectives, team workflow overview | — |
| 09:15 – 10:30 | **Block 11** | CI/CD Pipeline Engineering with Make & Act | Pipeline Badge |
| 10:30 – 10:45 | *Break* | | |
| 10:45 – 12:00 | **Block 12** | Kubernetes Deployment Strategy (kind + Helm + Kustomize) | Strategist Badge |
| 12:00 – 13:00 | *Lunch* | | |
| 13:00 – 14:15 | **Block 13** | Load Testing & Traffic Management (k6 + Shadow) | Load Tester Badge |
| 14:15 – 14:30 | *Break* | | |
| 14:30 – 15:45 | **Block 14** | Confluent Cloud Automation & Operational Runbooks | Commander Badge |
| 15:45 – 16:30 | **Block 15** | End-to-End Release Simulation | General Badge |
| 16:30 – 17:00 | Closing | Recap, Level 401 preview | Workshop Master |

---

## Block 11 — CI/CD Pipeline Engineering

### Goal: Earn the **Pipeline Badge**

---

### Step 11.1 — Design a Complete CI Pipeline (20 min)

Build a `Makefile`-driven CI pipeline that Act can run locally:

```bash
# The CI pipeline should execute in this order:
make ci-lint          # Checkstyle / spotbugs
make ci-build         # mvn compile
make ci-test          # mvn test (unit + topology tests)
make ci-integration   # Testcontainers integration tests
make ci-docker        # Docker image build
make ci-scan          # Trivy vulnerability scan
make ci-k8s-validate  # kustomize build + kubeval
```

**Task:** Add `ci-lint` and `ci-k8s-validate` targets to the Makefile.

```makefile
.PHONY: ci-lint
ci-lint:                                       ## Run static analysis
	mvn spotbugs:check -B

.PHONY: ci-k8s-validate
ci-k8s-validate:                               ## Validate K8s manifests
	kubectl kustomize k8s/overlays/dev/ > /dev/null
	kubectl kustomize k8s/overlays/qa/ > /dev/null
	kubectl kustomize k8s/overlays/prod/ > /dev/null
	@echo "[PASS] All Kustomize overlays render successfully"
```

---

### Step 11.2 — Run the Full Pipeline Locally with Act (20 min)

```bash
# Create a comprehensive CI workflow
cat > .github/workflows/ci-full.yaml << 'YAML_EOF'
name: CI Full Pipeline
on: [push]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: temurin, cache: maven }
      - run: make ci-lint

  build-and-test:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: temurin, cache: maven }
      - run: make ci-build ci-test

  docker-and-scan:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make ci-docker ci-scan

  k8s-validate:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make ci-k8s-validate
YAML_EOF

# Run it locally
act push --workflows .github/workflows/ci-full.yaml
```

---

### Step 11.3 — Implement a PR Quality Gate (15 min)

**Task:** Create a workflow that runs on PRs and posts a summary comment:

```yaml
# .github/workflows/pr-check.yaml
name: PR Quality Gate
on:
  pull_request:
    branches: [develop, main]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: temurin, cache: maven }
      - name: Build & Test
        run: make ci-build ci-test
      - name: K8s Manifest Validation
        run: make ci-k8s-validate
      - name: Security Scan
        run: make ci-scan
```

Test locally: `act pull_request --workflows .github/workflows/pr-check.yaml`

---

### Step 11.4 — Checkpoint

```bash
./scripts/workshop-check.sh block11
```

---

## Block 12 — Kubernetes Deployment Strategy

### Goal: Earn the **Strategist Badge**

---

### Step 12.1 — Design a Multi-Environment kind Setup (15 min)

Create isolated namespaces simulating DEV, QA, PROD on a single kind cluster:

```bash
# Create cluster
kind create cluster --name multi-env --config kind-cluster.yaml

# Deploy all three overlays
kubectl apply -k k8s/overlays/dev/
kubectl apply -k k8s/overlays/qa/
kubectl apply -k k8s/overlays/prod/

# Compare deployments across environments
echo "=== DEV ===" && kubectl get deploy -n confluent-apps-dev
echo "=== QA ===" && kubectl get deploy -n confluent-apps-qa
echo "=== PROD ===" && kubectl get deploy -n confluent-apps-prod
```

---

### Step 12.2 — Create a Helm Chart for the Payment App (30 min)

**Task:** Convert the Kustomize base into a parameterized Helm chart.

```bash
# Scaffold the chart
helm create helm/payment-app

# Replace the default templates with our K8s manifests
# Then parameterize values: replicaCount, image.tag, resources, env
```

Key values to parameterize:

```yaml
# helm/payment-app/values.yaml
replicaCount: 1
image:
  repository: registry.example.com/confluent-ps/producer-consumer-app
  tag: "1.0.0-SNAPSHOT"
  pullPolicy: IfNotPresent

kafka:
  bootstrapServers: ""           # set per environment
  securityProtocol: "SASL_SSL"
  schemaRegistryUrl: ""

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 768Mi

networkPolicy:
  enabled: true
  egressPorts:
    - 9092   # Kafka
    - 443    # Schema Registry
```

**Test:**
```bash
helm template payment-app ./helm/payment-app --values helm/payment-app/values-dev.yaml
helm install payment-app ./helm/payment-app -n confluent-apps-dev \
  --values helm/payment-app/values-dev.yaml --dry-run
```

---

### Step 12.3 — Rolling Update vs. Blue-Green (15 min)

**Discuss and implement:**

```bash
# Rolling update (default)
kubectl set image deployment/fraud-detection \
  fraud-detection=fraud-detection:v1.1.0 -n confluent-apps-dev

# Watch the rollout
kubectl rollout status deployment/fraud-detection -n confluent-apps-dev

# Rollback if needed
kubectl rollout undo deployment/fraud-detection -n confluent-apps-dev

# Helm rollback
helm rollback payment-app 1 -n confluent-apps-dev
```

**Question:** For a KStreams app with state stores, what is the safest deployment strategy? (Answer: rolling update with `maxUnavailable=1` and standby replicas.)

---

### Step 12.4 — Clean Up & Checkpoint

```bash
kind delete cluster --name multi-env
./scripts/workshop-check.sh block12
```

---

## Block 13 — Load Testing & Traffic Management

### Goal: Earn the **Load Tester Badge**

---

### Step 13.1 — Build a k6 Test Suite (25 min)

**Task:** Create a comprehensive load test with multiple scenarios:

```javascript
// tests/load/full-pipeline-test.js
import { payment_flow } from './scenarios/payment.js';
import { fraud_check_flow } from './scenarios/fraud.js';

export const options = {
  scenarios: {
    normal_load: {
      executor: 'ramping-vus',
      exec: 'payment_flow',
      stages: [
        { duration: '1m', target: 20 },
        { duration: '3m', target: 20 },
        { duration: '1m', target: 0 },
      ],
    },
    spike_test: {
      executor: 'ramping-vus',
      exec: 'payment_flow',
      startTime: '5m',
      stages: [
        { duration: '10s', target: 100 },   // sudden spike
        { duration: '1m', target: 100 },
        { duration: '10s', target: 0 },
      ],
    },
  },
  thresholds: {
    'http_req_duration{scenario:normal_load}': ['p(95)<200'],
    'http_req_duration{scenario:spike_test}': ['p(95)<1000'],
    errors: ['rate<0.01'],
  },
};
```

```bash
# Run the full test suite
k6 run tests/load/full-pipeline-test.js

# Run and export to JSON for analysis
k6 run --out json=results/load-test.json tests/load/full-pipeline-test.js
```

---

### Step 13.2 — Integrate k6 into CI (15 min)

Add to the CI pipeline:

```makefile
.PHONY: ci-load-test
ci-load-test:                                  ## Run load tests with pass/fail thresholds
	k6 run --quiet tests/load/payment-producer-test.js
```

```yaml
# Add to .github/workflows/ci-full.yaml
  load-test:
    needs: docker-and-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/load/payment-producer-test.js
```

---

### Step 13.3 — Design a Shadow Traffic Strategy (20 min)

**Team Exercise:** Draw the traffic flow for validating a new KStreams topology:

1. Mirror `payments` topic from PROD → QA via Cluster Linking
2. Run old topology (v1.0) and new topology (v1.1) side-by-side in QA
3. Compare `fraud-alerts` output from both versions
4. Validate: new version flags same or fewer false positives

```bash
# Pseudo-commands (requires Confluent Cloud):
confluent kafka link create prod-to-qa \
  --source-cluster lkc-prod --cluster lkc-qa

confluent kafka mirror create payments \
  --link prod-to-qa --cluster lkc-qa

# In QA: run both topologies with different application.id
# v1.0: fraud-detection-app-stable  -> fraud-alerts-stable
# v1.1: fraud-detection-app-canary  -> fraud-alerts-canary

# Compare outputs
kcat -b $QA_BOOTSTRAP -t fraud-alerts-stable -C -J -o beginning -e > stable.json
kcat -b $QA_BOOTSTRAP -t fraud-alerts-canary -C -J -o beginning -e > canary.json
diff <(jq -S . stable.json) <(jq -S . canary.json)
```

---

### Step 13.4 — Checkpoint

```bash
./scripts/workshop-check.sh block13
```

---

## Block 14 — Confluent Cloud Automation & Operational Runbooks

### Goal: Earn the **Commander Badge**

---

### Step 14.1 — Script a Full Environment Setup (25 min)

**Task:** Extend `ccloud-setup.sh` to include:
- Service account creation
- ACL configuration (least privilege)
- API key rotation schedule

```bash
# Create a service account
confluent iam service-account create payment-app-sa \
  --description "Payment App Service Account"

# Create ACLs (least privilege — PCI-DSS Req 7)
SA_ID=sa-12345
confluent kafka acl create --allow --service-account $SA_ID \
  --operations READ,WRITE --topic payments --prefix
confluent kafka acl create --allow --service-account $SA_ID \
  --operations READ --consumer-group payment-consumer-group --prefix
```

---

### Step 14.2 — Build an Operational Runbook Script (25 min)

**Task:** Create `scripts/ops-runbook.sh` with day-2 operations:

```bash
#!/usr/bin/env bash
# ops-runbook.sh — Day-2 operational procedures

case "$1" in
  check-health)    # Quick cluster health check
    confluent kafka cluster describe
    confluent kafka consumer group lag describe payment-consumer-group
    ;;
  rotate-keys)     # API key rotation
    echo "Creating new key..."
    confluent api-key create --resource $CLUSTER_ID --service-account $SA_ID
    echo "Update K8s Secret, then delete old key."
    ;;
  scale-consumers) # Scale consumer pods
    kubectl scale deployment/payment-consumer -n $NAMESPACE --replicas=$2
    ;;
  reset-offsets)   # Reset consumer offsets (QA only!)
    echo "WARNING: This resets offsets. Continue? (y/N)"
    read -r confirm
    [ "$confirm" = "y" ] && confluent kafka consumer group lag reset \
      --group payment-consumer-group --topic payments --to-earliest
    ;;
esac
```

---

### Step 14.3 — kcat Scripted Validation (15 min)

**Task:** Write a validation script that uses kcat to verify data flow:

```bash
#!/usr/bin/env bash
# validate-pipeline.sh — verify end-to-end data flow

echo "==> Producing test message..."
TXNID="validate-$(date +%s)"
echo "${TXNID}|{\"transaction_id\":\"${TXNID}\",\"amount\":50.00,\"region\":\"US-EAST\"}" | \
  kcat -b localhost:9092 -t payments -P -K "|"

sleep 5  # wait for KStreams processing

echo "==> Checking approved-payments..."
RESULT=$(kcat -b localhost:9092 -t approved-payments -C -o -10 -e 2>/dev/null | grep "$TXNID")
if [ -n "$RESULT" ]; then
  echo "[PASS] Message found in approved-payments"
else
  echo "[FAIL] Message NOT found in approved-payments"
fi
```

---

### Step 14.4 — Checkpoint

```bash
./scripts/workshop-check.sh block14
```

---

## Block 15 — End-to-End Release Simulation

### Goal: Earn the **General Badge**

> *The general leads the campaign. You orchestrate the release.*

---

### Step 15.1 — Simulate a Full Release (45 min)

Execute the complete release lifecycle using all tools:

```bash
# 1. Feature development (Git-Flow)
git checkout -b feature/new-fraud-rule develop

# 2. Make code changes (add a new fraud rule)
# ... edit FraudDetectionTopology.java ...

# 3. Local validation
make build test                    # Maven build + unit tests
act push --job build               # CI simulation

# 4. Commit and push
git add -A && git commit -m "feat: add merchant velocity fraud rule"
git push -u origin feature/new-fraud-rule

# 5. Create PR to develop
gh pr create --base develop --title "feat: merchant velocity rule"

# 6. After merge to develop: verify QA deployment
make k8s-qa                        # Apply QA overlay
k6 run tests/load/payment-producer-test.js  # Load test

# 7. Release branch
git checkout -b release/1.1.0 develop

# 8. Release validation
make ci                            # Full CI
make docker-build                  # Container images

# 9. PROD promotion (GitOps PR — created by CD pipeline)
# ... operations team reviews and approves ...

# 10. Post-deployment validation
./scripts/diagnose.sh full         # Health checks
./scripts/ops-runbook.sh check-health  # Operational check
```

---

### Step 15.2 — Review & Retrospective (15 min)

**Discuss as a team:**
1. Where did the toolchain provide the most value?
2. Which step took the longest? How can we optimize it?
3. What would break if we skipped a step?
4. How does this workflow satisfy PCI-DSS Req 6 (secure development)?

---

### Step 15.3 — Checkpoint

```bash
./scripts/workshop-check.sh block15
```

---

## Level 301 Complete!

```bash
./scripts/workshop-check.sh level301
```

```
  ================================================
    WERKSTATT-MEISTER — Level 301 Complete!
    You can plan, build, test, and release
    with the full tool suite.
    Next: Level 401 — Art of Optimization.
  ================================================
```
