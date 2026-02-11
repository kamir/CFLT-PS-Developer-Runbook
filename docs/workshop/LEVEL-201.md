# Level 201 — Know the Tools

> *Know your tools.*
> Half-day workshop (4h) — builds on Level 101 (Blocks 1–6).

---

## Prerequisites

- All 6 Badges from Level 101 earned (Master Badge)
- Tools installed: `make`, `act`, `kind`, `helm`, `k6`, `ngrok`, `kcat`, `confluent`

```bash
# Verify all tools
make --version && act --version && kind --version && helm version && \
k6 version && ngrok version && kcat -V && confluent version
```

---

## Schedule

| Time | Block | Topic | Badge |
|---|---|---|---|
| 09:00 – 09:15 | Opening | Level 201 objectives, tool landscape | — |
| 09:15 – 10:15 | **Block 7** | Make & Act — Build Automation | Smith Badge |
| 10:15 – 10:30 | *Break* | | |
| 10:30 – 11:30 | **Block 8** | kind & Helm — Local K8s | Knight Badge |
| 11:30 – 12:00 | **Block 9** | k6, ngrok & Shadow Traffic — Testing | Inspector Badge |
| 12:00 – 12:45 | **Block 10** | Confluent CLI, Kafka CLI & kcat — Mastery | Messenger Badge |
| 12:45 – 13:00 | Closing | Recap, Level 301 preview | Tool Master |

---

## Block 7 — Make & Act: Build Automation

### Goal: Earn the **Smith Badge** (Blacksmith)

> *The blacksmith forges the tools. You master the build system.*

---

### Step 7.1 — Explore the Makefile (10 min)

```bash
# See all available targets
make help

# Run the most common sequence
make build

# Run full CI locally
make ci
```

**Observe:** Every command you learned in Level 101 is now a single `make` target.

**Questions:**
1. How many targets does the Makefile define?
2. What does `make local-up` do compared to the manual docker-compose commands?
3. Why is a Makefile valuable for team standardization?

---

### Step 7.2 — Add a Custom Make Target (15 min)

**Task:** Add a `make smoke-test` target that:
1. Starts the local stack
2. Creates topics
3. Runs the producer for 5 seconds
4. Checks that messages exist in the payments topic
5. Tears down

Edit the `Makefile` and add:

```makefile
.PHONY: smoke-test
smoke-test: local-up topics                    ## Run a quick smoke test
	@echo "==> Starting producer for 5 seconds..."
	timeout 5 java -Dapp.env=dev \
	  -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
	  produce || true
	@echo "==> Checking messages..."
	kcat -b localhost:9092 -t payments -C -o beginning -c 1 -e \
	  && echo "[PASS] Smoke test passed" \
	  || echo "[FAIL] No messages found"
```

Run it:
```bash
make smoke-test
```

---

### Step 7.3 — Run GitHub Actions Locally with Act (15 min)

```bash
# List all jobs in the CI workflow
act --list --workflows .github/workflows/ci.yaml

# Run the build job locally
act push --workflows .github/workflows/ci.yaml --job build

# Dry-run to see what would happen
act push --workflows .github/workflows/ci.yaml --dryrun
```

**Observe:** The same CI pipeline that runs on GitHub now runs on your laptop.

**Task:** Create a test event file and run the CI with it:

```bash
mkdir -p .github/test-events

cat > .github/test-events/push-develop.json << 'EOF'
{
  "ref": "refs/heads/develop",
  "repository": { "default_branch": "main" }
}
EOF

act push --workflows .github/workflows/ci.yaml \
  --eventpath .github/test-events/push-develop.json
```

---

### Step 7.4 — Checkpoint

```bash
./scripts/workshop-check.sh block7
```

```
  >>> SMITH BADGE EARNED! <<<
```

---

## Block 8 — kind & Helm: Local Kubernetes

### Goal: Earn the **Knight Badge**

> *The knight commands the field. You command the cluster.*

---

### Step 8.1 — Create a Local K8s Cluster with kind (10 min)

```bash
# Create a 3-node cluster
kind create cluster --name kafka-workshop --config kind-cluster.yaml

# Verify
kubectl cluster-info --context kind-kafka-workshop
kubectl get nodes
```

Expected:
```
NAME                           STATUS   ROLES           AGE
kafka-workshop-control-plane   Ready    control-plane   30s
kafka-workshop-worker          Ready    <none>          25s
kafka-workshop-worker2         Ready    <none>          25s
```

---

### Step 8.2 — Load Docker Images into kind (5 min)

```bash
# Build images (if not already done)
make docker-build

# Load them into kind (no registry push needed!)
kind load docker-image payment-app:workshop --name kafka-workshop
kind load docker-image fraud-detection:workshop --name kafka-workshop
```

---

### Step 8.3 — Deploy with Kustomize (10 min)

```bash
# Apply the dev overlay
kubectl apply -k k8s/overlays/dev/

# Watch pods come up
kubectl get pods -n confluent-apps-dev -w

# Check the NetworkPolicy
kubectl describe networkpolicy -n confluent-apps-dev
```

---

### Step 8.4 — Deploy with Helm (20 min)

```bash
# Look at the chart structure
ls helm/payment-app/

# Template rendering (dry-run)
helm template payment-app ./helm/payment-app \
  --values helm/payment-app/values-dev.yaml

# Install
helm install payment-app ./helm/payment-app \
  --namespace confluent-apps-dev \
  --values helm/payment-app/values-dev.yaml \
  --create-namespace

# Check release status
helm list -n confluent-apps-dev

# Upgrade with a new value
helm upgrade payment-app ./helm/payment-app \
  --namespace confluent-apps-dev \
  --set replicaCount=2

# Rollback
helm rollback payment-app 1 -n confluent-apps-dev
```

---

### Step 8.5 — Clean Up (5 min)

```bash
kind delete cluster --name kafka-workshop
```

---

### Step 8.6 — Checkpoint

```bash
./scripts/workshop-check.sh block8
```

```
  >>> KNIGHT BADGE EARNED! <<<
```

---

## Block 9 — k6, ngrok & Shadow Traffic: Testing

### Goal: Earn the **Inspector Badge**

> *The inspector tests everything. You validate under pressure.*

---

### Step 9.1 — Write and Run a k6 Load Test (15 min)

```bash
# Look at the provided load test script
cat tests/load/payment-producer-test.js

# Run with 10 virtual users for 30 seconds
k6 run --vus 10 --duration 30s tests/load/payment-producer-test.js
```

**Observe the output:**
- `http_req_duration` — request latency distribution
- `errors` — error rate
- `iterations` — total requests completed

**Task:** Modify the test thresholds:
- 99th percentile latency < 1000ms
- Error rate < 0.5%

---

### Step 9.2 — Expose Local Service with ngrok (10 min)

```bash
# Start a simple HTTP listener (or your actual API)
python3 -m http.server 8080 &

# Expose via ngrok
ngrok http 8080
```

**Observe:** You now have a public URL. Open `http://127.0.0.1:4040` to see ngrok's inspection UI.

Stop ngrok and the HTTP server when done.

---

### Step 9.3 — Discuss Shadow Traffic Patterns (5 min)

Review the three shadow traffic approaches from `TOOLS.md`:
1. **Confluent Cluster Linking** — topic mirroring between clusters
2. **Istio Traffic Mirroring** — HTTP-level request duplication
3. **Application-Level** — fire-and-forget async forwarding

**Question:** Which approach fits our payment pipeline best? Why?

---

### Step 9.4 — Checkpoint

```bash
./scripts/workshop-check.sh block9
```

```
  >>> INSPECTOR BADGE EARNED! <<<
```

---

## Block 10 — Confluent CLI, Kafka CLI & kcat: Mastery

### Goal: Earn the **Messenger Badge** (Herald)

> *The herald knows every message. You master every CLI.*

---

### Step 10.1 — Confluent CLI Deep Dive (15 min)

```bash
# If you have Confluent Cloud access:
confluent login
confluent environment list
confluent kafka cluster list

# Create a topic with specific config
confluent kafka topic create workshop-test \
  --partitions 3 \
  --config retention.ms=3600000

# Produce and consume
echo "test-key|test-value" | confluent kafka topic produce workshop-test \
  --parse-key --delimiter="|"
confluent kafka topic consume workshop-test --from-beginning --print-key

# Clean up
confluent kafka topic delete workshop-test
```

If no cloud access, practice with the local Kafka CLI tools:

```bash
# Advanced consumer group management
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group payment-consumer-group --members --verbose

# Describe broker configs
kafka-configs --bootstrap-server localhost:9092 \
  --entity-type brokers --entity-name 1 --describe --all
```

---

### Step 10.2 — kcat Power Session (15 min)

```bash
# JSON output with jq processing
kcat -b localhost:9092 -t payments -C -J -o beginning -c 10 -e | \
  jq '.payload | {key: .key, amount: (.val | fromjson | .amount)}'

# Count messages per partition
kcat -b localhost:9092 -t payments -C -o beginning -e -f '%p\n' | \
  sort | uniq -c | sort -rn

# Produce a batch from file
cat > /tmp/test-batch.jsonl << 'EOF'
txn-batch-1|{"transaction_id":"txn-batch-1","amount":100}
txn-batch-2|{"transaction_id":"txn-batch-2","amount":200}
txn-batch-3|{"transaction_id":"txn-batch-3","amount":300}
EOF

kcat -b localhost:9092 -t payments -P -K "|" -l /tmp/test-batch.jsonl

# Verify
kcat -b localhost:9092 -t payments -C -o -3 -e
```

---

### Step 10.3 — Checkpoint

```bash
./scripts/workshop-check.sh block10
```

```
  >>> MESSENGER BADGE EARNED! <<<
```

---

## Level 201 Complete!

```bash
./scripts/workshop-check.sh level201
```

```
  ================================================
    WERKZEUG-MEISTER — Level 201 Complete!
    You know every tool in the box.
    Next: Level 301 — Master the Workshop.
  ================================================
```
