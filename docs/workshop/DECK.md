---
marp: true
theme: default
paginate: true
backgroundColor: #fff
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
  }
  section.title {
    text-align: center;
    background: linear-gradient(135deg, #172a45 0%, #1a3a5c 100%);
    color: white;
  }
  section.title h1 {
    font-size: 2.5em;
    color: white;
  }
  section.title h2 {
    color: #64b5f6;
  }
  section.divider {
    text-align: center;
    background: #0a2540;
    color: white;
  }
  section.divider h1 {
    font-size: 2.8em;
    color: #64b5f6;
  }
  table { font-size: 0.8em; }
  code { font-size: 0.85em; }
  .sporn { font-size: 1.4em; }
---

<!-- _class: title -->

# Confluent Cloud
# Java Developer Toolkit

## Hands-On Workshop

### *Von der ersten Zeile bis zur Produktion*

---

<!-- _class: title -->

## Agenda

| Block | Topic | Sporn |
|---|---|---|
| 1 | Local Dev Environment & First Messages | Bronzener Sporn |
| 2 | Producer/Consumer Deep Dive & PCI-DSS | Silberner Sporn |
| 3 | Kafka Streams — Fraud Detection | Goldener Sporn |
| 4 | Configuration & Git-Flow | Eiserner Sporn |
| 5 | Docker, Kubernetes & GitOps | Stahlerner Sporn |
| 6 | Troubleshooting & Diagnostics | Diamantener Sporn |

**Earn all 6 Sporen = Meister-Sporn**

---

# What We're Building

A **payment processing pipeline** on Confluent Cloud:

```
+-----------+    payments     +------------------+    fraud-alerts    +---------+
| Payment   | -------------> | Fraud Detection  | -----------------> | Alert   |
| Producer  |                | (Kafka Streams)  |                    | System  |
+-----------+                |                  |                    +---------+
                             | approved-payments|
                             | ---------------> |  Downstream
                             +------------------+  Processing
```

- **PCI-DSS compliant** — card numbers masked before Kafka
- **3 environments** — DEV, QA, PROD
- **Git-Flow + GitOps** — code and config via GitHub

---

# Environment Promotion Model

```
  DEV                      QA                       PROD
+----------------+    +------------------+    +----------------------+
| Local broker   |    | Confluent Cloud  |    | Confluent Cloud      |
| docker-compose | -> | Dedicated cluster| -> | Dedicated cluster    |
|                |    |                  |    |                      |
| Manual tasks   |    | All params       |    | Code + configs via   |
| Self-service   |    | scripted in      |    | GitHub PR to Ops     |
|                |    | config files     |    | team for approval    |
+----------------+    +------------------+    +----------------------+
```

> **Key Principle:** What's manual in DEV must be automated in QA and handed over in PROD.

---

# Repository Structure

```
confluent-java-toolkit/
+-- pom.xml                         # Parent POM
|
+-- producer-consumer-app/          # Block 1 + 2
|   +-- src/main/java/...           # Producer, Consumer, ConfigLoader
|   +-- src/main/avro/              # Payment schema
|   +-- src/main/resources/         # Config per environment
|   +-- src/test/                   # Unit tests
|
+-- kstreams-app/                   # Block 3
|   +-- src/main/java/...           # FraudDetectionApp + Topology
|   +-- src/test/                   # TopologyTestDriver tests
|
+-- docker/                         # Block 5
+-- k8s/                            # Block 5 (Kustomize)
+-- scripts/                        # Blocks 1 + 6
+-- .github/workflows/              # Block 5 (CI/CD)
+-- RUNBOOK.md                      # Full reference
```

---

<!-- _class: divider -->

# Block 1
# Local Dev Environment
# & First Messages

<p class="sporn">Bronzener Sporn</p>

---

# Block 1 — The Local Stack

```yaml
# docker/docker-compose.yml
services:
  broker:                          # Kafka (KRaft mode)
    image: confluentinc/cp-kafka:7.7.0
    ports: ["9092:9092"]

  schema-registry:                 # Schema Registry
    image: confluentinc/cp-schema-registry:7.7.0
    ports: ["8081:8081"]
```

**Start it:**
```bash
cd docker && docker-compose up -d broker schema-registry
```

**Verify:**
```bash
docker exec broker kafka-topics --bootstrap-server localhost:9092 --list
```

---

# Block 1 — Create Topics

```bash
./scripts/create-topics.sh local
```

Output:
```
==> Creating topics on local broker (localhost:9092)...
  [OK] payments
  [OK] fraud-alerts
  [OK] approved-payments
==> Done.
```

Three topics, one pipeline:
- `payments` — raw payment events (input)
- `fraud-alerts` — flagged transactions (KStreams output)
- `approved-payments` — clean transactions (KStreams output)

---

# Block 1 — Build & Run

```bash
# Build everything
mvn clean package -DskipTests

# Terminal 1: Start the producer
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     produce

# Terminal 2: Start the consumer
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     consume
```

You should see:
```
INFO PaymentProducer - Sent payment txn_id=a1b2... partition=2 offset=0
INFO PaymentConsumer - Received payment: partition=2 offset=0 key=a1b2...
```

---

# Block 1 — Explore with kcat

```bash
# List topic metadata
kcat -b localhost:9092 -L

# Consume and format output
kcat -b localhost:9092 -t payments -C \
  -f 'P:%p | O:%o | K:%k | V:%s\n' \
  -o beginning -c 5
```

Output:
```
P:0 | O:0 | K:abc-123 | V:{"transaction_id":"abc-123","card_number_masked":"****-...
P:2 | O:0 | K:def-456 | V:{"transaction_id":"def-456","card_number_masked":"****-...
```

> Notice: Card numbers are **always masked** — `****-****-****-1234`

---

# Block 1 — Checkpoint

## Validate your Bronzener Sporn

```bash
./scripts/workshop-check.sh block1
```

Expected:
```
========================================
  Block 1 — Bronzener Sporn
========================================
  [PASS] Docker containers running (broker, schema-registry)
  [PASS] Topic 'payments' exists with 6 partitions
  [PASS] Topic 'fraud-alerts' exists
  [PASS] Topic 'approved-payments' exists
  [PASS] Messages found in 'payments' topic

  >>> BRONZENER SPORN EARNED! <<<
```

---

<!-- _class: divider -->

# Block 2
# Producer / Consumer
# Deep Dive & PCI-DSS

<p class="sporn">Silberner Sporn</p>

---

# Block 2 — Producer Internals

## Key Producer Settings for PCI-DSS

```properties
# Maximum durability
acks=all                            # All in-sync replicas must acknowledge

# Exactly-once delivery
enable.idempotence=true             # Prevents duplicate messages
retries=10                          # Automatic retry on transient errors
max.in.flight.requests.per.connection=5  # Required for idempotence
```

```java
// PaymentProducer.java
props.putIfAbsent(ProducerConfig.ACKS_CONFIG, "all");
props.putIfAbsent(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
```

> **PCI-DSS Req 6:** Data integrity — no lost, no duplicate payments.

---

# Block 2 — PCI-DSS: Card Number Masking

## The Golden Rule: Mask BEFORE Producing

```java
// PaymentProducer.java — line 97
static String buildPaymentJson(String txnId, int sequence) {
    // PAN is NEVER stored in full
    String maskedCard = "****-****-****-"
        + String.format("%04d", (sequence % 9999) + 1);

    return String.format(
        "{\"transaction_id\":\"%s\","
      + "\"card_number_masked\":\"%s\","    // <-- masked!
      + "\"amount\":%.2f, ...}", txnId, maskedCard, amount);
}
```

**PCI-DSS Req 3:** Protect stored cardholder data
- Full PAN must **never** appear in Kafka, logs, or configs
- Only last 4 digits retained for reference

---

# Block 2 — Consumer Internals

## Manual Offset Commit (PCI-DSS Best Practice)

```java
// PaymentConsumer.java
props.putIfAbsent(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");

while (running.get()) {
    ConsumerRecords<String, String> records =
        consumer.poll(Duration.ofMillis(1000));

    if (!records.isEmpty()) {
        records.forEach(record -> {
            // Process the payment...
            // IMPORTANT: Never log full card numbers!
        });

        // Commit AFTER successful processing
        consumer.commitSync();
    }
}
```

> **Why manual commit?** Auto-commit can mark messages as processed before your business logic finishes. A crash = data loss.

---

# Block 2 — Lab Exercise

## Your Task:

1. **Add a new field** `country_code` (String) to the producer's JSON output
2. **Add a filter** in the consumer: only log payments where `amount > 100`
3. **Run the unit tests** to verify: `mvn test -pl producer-consumer-app`

**Hint for the filter:**
```java
records.forEach(record -> {
    // Parse amount from JSON (simplified)
    if (record.value().contains("\"amount\":")) {
        // Your filter logic here
    }
});
```

**Validate:** `./scripts/workshop-check.sh block2`

---

<!-- _class: divider -->

# Block 3
# Kafka Streams
# Fraud Detection

<p class="sporn">Goldener Sporn</p>

---

# Block 3 — KStreams Architecture

```
                    +-- FraudDetectionTopology --+
                    |                            |
payments  -------->| 1. Read payment events     |
(input)            | 2. Enrich with risk_score  |
                   | 3. Branch:                 |
                   |    score > 0.7 --> flagged  |------> fraud-alerts
                   |    score <= 0.7 -> approved |------> approved-payments
                   +----------------------------+
```

- **Stateless** topology (no state stores in this example)
- **Deterministic** — same input always produces same output
- **Testable** — TopologyTestDriver runs without a broker

---

# Block 3 — The Topology Code

```java
// FraudDetectionTopology.java
KStream<String, String> payments = builder.stream(INPUT_TOPIC);

// Step 1: Enrich with risk score
KStream<String, String> scored = payments
    .mapValues((key, value) -> enrichWithRiskScore(key, value));

// Step 2: Branch
scored.split(Named.as("fraud-check-"))
    .branch(
        (key, value) -> isFraudulent(value),    // risk_score > 0.7
        Branched.withConsumer(flagged ->
            flagged.to(FRAUD_ALERTS_TOPIC))
    )
    .defaultBranch(
        Branched.withConsumer(approved ->
            approved.to(APPROVED_TOPIC))
    );
```

---

# Block 3 — Risk Scoring Rules

```java
static double computeRiskScore(double amount, String paymentJson) {
    double score = 0.0;

    // Rule 1: High-value transactions
    if (amount > 1000.00) score += 0.4;
    if (amount > 5000.00) score += 0.3;

    // Rule 2: High-risk regions
    if (paymentJson.contains("\"region\":\"AP-SOUTH\""))
        score += 0.2;

    // Rule 3: Round amounts are suspicious
    if (amount == Math.floor(amount) && amount > 500)
        score += 0.15;

    return Math.min(score, 1.0);
}
```

| Scenario | Amount | Region | Score | Flagged? |
|---|---|---|---|---|
| Normal purchase | 50.00 | US-EAST | 0.00 | No |
| High value | 2000.00 | US-WEST | 0.40 | No |
| High value + risky region | 7500.00 | AP-SOUTH | 0.90 | **Yes** |

---

# Block 3 — Testing with TopologyTestDriver

```java
// FraudDetectionTopologyTest.java — no broker needed!
@Test
void highValueTransaction_fromHighRiskRegion_shouldBeFlagged() {
    String payment = "{\"transaction_id\":\"txn-fraud\","
        + "\"amount\":7500.00,"
        + "\"region\":\"AP-SOUTH\", ...}";

    inputTopic.pipeInput("txn-fraud", payment);     // feed test data

    assertFalse(fraudAlertsTopic.isEmpty());         // must trigger alert
    String alert = fraudAlertsTopic.readValue();
    assertTrue(alert.contains("\"risk_score\":"));   // enriched
}
```

**Run all 8 tests:**
```bash
mvn test -pl kstreams-app
```

---

# Block 3 — Lab Exercise

## Your Task: Add a Velocity Check Rule

Idea: Transactions > 3000 with `merchant_id=MERCH-004` are suspicious.

1. **Add a new rule** in `computeRiskScore()`:
   ```java
   if (amount > 3000.00 && paymentJson.contains("MERCH-004"))
       score += 0.35;
   ```
2. **Write a test** for this rule in `FraudDetectionTopologyTest`
3. **Run all tests**: `mvn test -pl kstreams-app`
4. **Start the KStreams app** and observe fraud-alerts vs. approved

**Validate:** `./scripts/workshop-check.sh block3`

---

<!-- _class: divider -->

# Block 4
# Configuration
# & Git-Flow

<p class="sporn">Eiserner Sporn</p>

---

# Block 4 — ConfigLoader: 5 Layers

```
Layer 5 (highest):  KAFKA_BOOTSTRAP_SERVERS=...     (env var)
Layer 4:            -Dkafka.bootstrap.servers=...    (system property)
Layer 3:            -Dconfig.file=/path/to/file      (external file)
Layer 2:            application-dev.properties       (env overlay)
Layer 1 (lowest):   application.properties           (base defaults)
```

**Last wins.** Higher layers override lower layers.

```java
// Example: override bootstrap.servers via env var
export KAFKA_BOOTSTRAP_SERVERS="pkc-xxx.confluent.cloud:9092"
java -Dapp.env=qa -jar app.jar produce
// -> uses Confluent Cloud, not localhost
```

---

# Block 4 — Environments Compared

| Property | DEV | QA | PROD |
|---|---|---|---|
| `bootstrap.servers` | `localhost:9092` | ConfigMap | ConfigMap |
| `security.protocol` | PLAINTEXT | SASL_SSL | SASL_SSL |
| `sasl.jaas.config` | — | K8s Secret | Vault |
| `acks` | 1 (default) | all | all |
| `enable.idempotence` | false | true | true |
| `processing.guarantee` | — | exactly_once_v2 | exactly_once_v2 |

> **Rule:** DEV is permissive. QA matches PROD config. PROD is locked down.

---

# Block 4 — Git-Flow

```
main ----------*--------------------------*--------
               |                          |
               |    release/1.0.0         |
               |  +----*----*----+        |
               |  |              |        |
develop ---*---*--*--------------*--------*--*-----
           |      |              |           |
        feature/  |           feature/    feature/
        payment   |           alerts      metrics
```

| Branch | Purpose | Deploys to |
|---|---|---|
| `main` | Production-ready | PROD (via tag) |
| `develop` | Integration | QA (automatic) |
| `feature/*` | New work | DEV (local) |
| `release/*` | Stabilization | PROD (via PR) |
| `hotfix/*` | Emergency fix | PROD (via PR) |

---

# Block 4 — Lab Exercise

## Your Task:

1. **Test config override** with environment variables:
   ```bash
   export KAFKA_BOOTSTRAP_SERVERS="broker-override:9092"
   java -Dapp.env=dev -jar producer-consumer-app/target/*.jar produce
   # -> Check log output for the overridden bootstrap.servers
   ```

2. **Create a feature branch** and commit your Block 3 changes:
   ```bash
   git checkout -b feature/velocity-check
   git add -A && git commit -m "feat: add velocity fraud rule"
   ```

3. **Simulate a release**:
   ```bash
   git checkout -b release/1.1.0
   ```

**Validate:** `./scripts/workshop-check.sh block4`

---

<!-- _class: divider -->

# Block 5
# Docker, Kubernetes
# & GitOps

<p class="sporn">Stahlerner Sporn</p>

---

# Block 5 — Docker Multi-Stage Build

```dockerfile
# Stage 1: Build (large image with JDK + Maven)
FROM eclipse-temurin:17-jdk-alpine AS builder
COPY . .
RUN mvn package -DskipTests

# Stage 2: Runtime (small image with JRE only)
FROM eclipse-temurin:17-jre-alpine

# PCI-DSS: Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /build/target/*-shaded.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Security (PCI-DSS):**
- Minimal base image (Alpine)
- Non-root user
- No shell access in production

---

# Block 5 — Kubernetes with Kustomize

```
k8s/
+-- base/                    # Shared manifests
|   +-- namespace.yaml
|   +-- configmap.yaml       # Non-secret config
|   +-- secrets.yaml         # TEMPLATE only
|   +-- networkpolicy.yaml   # PCI-DSS Req 1
|   +-- producer-deployment.yaml
|   +-- kstreams-deployment.yaml
|
+-- overlays/
    +-- dev/kustomization.yaml    # 1 replica, small resources
    +-- qa/kustomization.yaml     # 2 replicas, medium
    +-- prod/kustomization.yaml   # 4 replicas, large
```

```bash
# Render manifests for QA
kubectl kustomize k8s/overlays/qa/

# Apply to cluster
kubectl apply -k k8s/overlays/qa/
```

---

# Block 5 — GitOps Flow

```
Developer        GitHub          CI/CD           ArgoCD         K8s
    |               |               |               |             |
    |-- push ------>|               |               |             |
    |               |-- trigger --->|               |             |
    |               |               |-- build ----->|             |
    |               |               |-- test ------>|             |
    |               |               |-- scan ------>|             |
    |               |<-- update k8s/|               |             |
    |               |               |               |-- detect -->|
    |               |               |               |-- sync ---->|
    |               |               |               |             |-- deploy
```

### PROD requires a PR:
- CI creates a PR to `k8s/overlays/prod/`
- PR includes **PCI-DSS checklist**
- **Operations team** must approve before merge

---

# Block 5 — Lab Exercise

## Your Task:

1. **Build Docker images**:
   ```bash
   docker build -f docker/Dockerfile.producer-consumer \
     -t payment-app:workshop .
   docker build -f docker/Dockerfile.kstreams \
     -t fraud-detection:workshop .
   ```

2. **Render K8s manifests** for each environment:
   ```bash
   kubectl kustomize k8s/overlays/dev/
   kubectl kustomize k8s/overlays/prod/
   # Compare: replica counts, resource limits
   ```

3. **Inspect the CI pipeline**: Read `.github/workflows/ci.yaml`

**Validate:** `./scripts/workshop-check.sh block5`

---

<!-- _class: divider -->

# Block 6
# Troubleshooting
# & Diagnostics

<p class="sporn">Diamantener Sporn</p>

---

# Block 6 — The Diagnostics Toolkit

```bash
./scripts/diagnose.sh full
```

Runs 6 checks:

| Check | What It Does |
|---|---|
| `connectivity` | TCP + Kafka protocol test to broker |
| `consumer-lag` | Shows lag per partition for consumer group |
| `topic-inspect` | Describes partitions, ISR, leader |
| `kstreams-state` | KStreams consumer group + internal topics |
| `schema-check` | Schema Registry health + subjects |
| `k8s-status` | Pod status, events, recent logs |

---

# Block 6 — Scenario 1: Broker Unreachable

**Symptom:**
```
TimeoutException: Topic payments not present in metadata after 60000 ms
```

**Diagnosis Steps:**
```bash
# 1. Check if broker container is running
docker ps | grep broker

# 2. Test TCP connectivity
kcat -b localhost:9092 -L 2>&1 | head -3

# 3. Check Docker network
docker network inspect docker_default
```

**Common Fix:**
```bash
# Restart the broker
cd docker && docker-compose restart broker
```

---

# Block 6 — Scenario 2: Consumer Lag

**Symptom:** Messages pile up, processing is slow.

```bash
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group payment-consumer-group
```
```
TOPIC      PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
payments   0          100             5000            4900   <-- problem!
payments   1          150             4800            4650
```

**Fix Options:**
1. Start more consumer instances (up to partition count)
2. Check for slow processing logic
3. Increase `max.poll.records`

---

# Block 6 — Scenario 3: Schema Compatibility

**Symptom:**
```
RestClientException: Schema being registered is incompatible (409)
```

**Diagnosis:**
```bash
# Check compatibility level
curl -s http://localhost:8081/config/payments-value | jq .

# Test compatibility before deploying
curl -X POST \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data @producer-consumer-app/src/main/avro/payment.avsc \
  http://localhost:8081/compatibility/subjects/payments-value/versions/latest
```

**Fix:** Follow Avro evolution rules — add fields with defaults, never remove required fields.

---

# Block 6 — Lab: Fix the Scenarios

## Your Task:

1. **Scenario A:** Stop the broker (`docker-compose stop broker`).
   Run `./scripts/diagnose.sh connectivity`. Observe the failure.
   Fix it and verify.

2. **Scenario B:** Start a producer but no consumer.
   Run `./scripts/diagnose.sh consumer-lag`. Observe lag growing.
   Start a consumer and watch lag decrease.

3. **Scenario C:** Try registering an incompatible schema change.
   Run `./scripts/diagnose.sh schema-check`. Fix compatibility.

**Validate:** `./scripts/workshop-check.sh block6`

---

<!-- _class: divider -->

# Meister-Sporn
# Recap & Certification

---

# What You've Earned Today

| Block | Sporn | Skill |
|---|---|---|
| 1 | Bronzener Sporn | Local environment, first Kafka messages |
| 2 | Silberner Sporn | Producer/Consumer, PCI-DSS masking |
| 3 | Goldener Sporn | Kafka Streams topology, testing |
| 4 | Eiserner Sporn | Configuration management, Git-Flow |
| 5 | Stahlerner Sporn | Docker, Kubernetes, GitOps |
| 6 | Diamantener Sporn | Troubleshooting, diagnostics |

**All 6 Sporen = Meister-Sporn**

> *"Sich die Sporen verdienen"*
> You've earned your spurs as a Confluent Cloud Java developer!

---

# Next Steps

1. **Get Confluent Cloud access** for your team's DEV environment
   ```bash
   ./scripts/ccloud-setup.sh dev
   ```

2. **Start your first feature branch** on a real project
   ```bash
   git checkout -b feature/my-first-feature develop
   ```

3. **Reference the RUNBOOK.md** — it's your daily companion

4. **Bookmark the tools:**
   - [Confluent Cloud Console](https://confluent.cloud)
   - [Confluent CLI Docs](https://docs.confluent.io/confluent-cli/current/)
   - [Kafka Streams Developer Guide](https://kafka.apache.org/documentation/streams/)

---

<!-- _class: title -->

# Vielen Dank!
# Questions?

### *RUNBOOK.md is your reference from here on.*

---

<!-- _class: title -->

# Appendix
## Rendering This Deck

Install [Marp CLI](https://github.com/marp-team/marp-cli):

```bash
npm install -g @marp-team/marp-cli

# Generate HTML slides
marp docs/workshop/DECK.md -o docs/workshop/deck.html

# Generate PDF
marp docs/workshop/DECK.md --pdf -o docs/workshop/deck.pdf

# Live preview with hot reload
marp docs/workshop/DECK.md --preview
```

Or use the **Marp for VS Code** extension for live preview in your IDE.
