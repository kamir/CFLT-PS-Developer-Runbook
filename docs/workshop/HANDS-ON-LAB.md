# Hands-On Lab Guide

> **Confluent Cloud Java Developer Toolkit**
> *Step-by-step procedure for the workshop participant*

---

## Prerequisites Checklist

Before we begin, verify your workstation:

```bash
java -version        # JDK 17+
mvn -version         # Maven 3.9+
docker --version     # Docker 24+
docker compose version  # Compose v2
git --version        # Git 2.40+
kcat -V              # kcat 1.7+ (optional but recommended)
```

Clone the repository if you haven't already:

```bash
git clone <repo-url>
cd CFLT-PS-Developer-Runbook
```

---

## Block 1 — Local Dev Environment & First Messages

### Goal: Earn the **Bronzener Sporn**

---

### Step 1.1 — Explore the Repository

Take 2 minutes to understand the structure:

```bash
ls -la
cat README.md
```

Key directories:
- `producer-consumer-app/` — Java producer and consumer
- `kstreams-app/` — Kafka Streams fraud detection
- `docker/` — Docker configs for local dev
- `k8s/` — Kubernetes manifests
- `scripts/` — Helper scripts

---

### Step 1.2 — Start the Local Kafka Environment

```bash
cd docker
docker compose up -d broker schema-registry
```

Wait for the services to be healthy (about 15–30 seconds):

```bash
# Check that both containers are running
docker compose ps
```

Expected output:
```
NAME              STATUS    PORTS
broker            running   0.0.0.0:9092->9092/tcp
schema-registry   running   0.0.0.0:8081->8081/tcp
```

Verify the broker is ready:

```bash
docker exec broker kafka-topics --bootstrap-server localhost:9092 --list
```

This should return an empty list (or internal topics). No errors = success.

---

### Step 1.3 — Create Topics

```bash
cd ..
./scripts/create-topics.sh local
```

Expected:
```
==> Creating topics on local broker (localhost:9092)...
  [OK] payments
  [OK] fraud-alerts
  [OK] approved-payments
==> Done.
```

Verify:
```bash
docker exec broker kafka-topics --bootstrap-server localhost:9092 --list
```

You should see all three topics.

---

### Step 1.4 — Build the Project

```bash
mvn clean package -DskipTests
```

This builds both modules. Watch for `BUILD SUCCESS` at the end.

Expected output (last lines):
```
[INFO] Reactor Summary:
[INFO]   Confluent Java Toolkit ...................... SUCCESS
[INFO]   Producer Consumer App ...................... SUCCESS
[INFO]   Kafka Streams App .......................... SUCCESS
[INFO] BUILD SUCCESS
```

If Maven downloads dependencies for the first time, this may take 2–3 minutes.

---

### Step 1.5 — Run the Producer

Open **Terminal 1**:

```bash
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     produce
```

You should see messages being sent every 500ms:

```
INFO PaymentProducer - PaymentProducer started — sending to topic 'payments'
INFO PaymentProducer - Sent payment txn_id=a1b2c3d4-... partition=2 offset=0
INFO PaymentProducer - Sent payment txn_id=e5f6g7h8-... partition=0 offset=0
```

**Leave this running.** It sends one payment event every 500 milliseconds.

---

### Step 1.6 — Run the Consumer

Open **Terminal 2**:

```bash
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     consume
```

You should see messages being received:

```
INFO PaymentConsumer - PaymentConsumer started — subscribed to topic 'payments'
INFO PaymentConsumer - Received payment: partition=2 offset=0 key=a1b2c3d4-...
INFO PaymentConsumer - Committed offsets — total consumed: 5
```

**Observe:**
- Messages have a `card_number_masked` field with `****-****-****-XXXX`
- Full card numbers are **never** visible (PCI-DSS Req 3)

---

### Step 1.7 — Explore with kcat

Open **Terminal 3**:

```bash
# List all topics and their partitions
kcat -b localhost:9092 -L

# Consume 5 messages with formatted output
kcat -b localhost:9092 -t payments -C \
  -f '\nPartition: %p\nOffset:    %o\nKey:       %k\nValue:     %s\n' \
  -o beginning -c 5
```

**Questions to answer:**
1. How many partitions does the `payments` topic have?
2. What format is the message value? (JSON)
3. Can you see any full credit card numbers? (You should not!)

---

### Step 1.8 — Checkpoint!

Stop the producer and consumer (Ctrl+C in both terminals).

Run the validation:

```bash
./scripts/workshop-check.sh block1
```

```
========================================
  Block 1 — Bronzener Sporn
========================================
  [PASS] Docker containers running (broker, schema-registry)
  [PASS] Topic 'payments' exists with partitions
  [PASS] Topic 'fraud-alerts' exists
  [PASS] Topic 'approved-payments' exists
  [PASS] Messages found in 'payments' topic

  >>> BRONZENER SPORN EARNED! <<<
```

---

## Block 2 — Producer/Consumer Deep Dive & PCI-DSS

### Goal: Earn the **Silberner Sporn**

---

### Step 2.1 — Study the Producer Code

Open `producer-consumer-app/src/main/java/io/confluent/ps/producer/PaymentProducer.java` in your IDE.

Key observations:
1. **Line ~58:** `acks=all` — waits for all replicas to acknowledge
2. **Line ~60:** `enable.idempotence=true` — prevents duplicate messages
3. **Line ~97:** `buildPaymentJson()` — card masking happens here
4. **Line ~74:** Callback pattern for async send with error handling

---

### Step 2.2 — Study the Consumer Code

Open `producer-consumer-app/src/main/java/io/confluent/ps/consumer/PaymentConsumer.java` in your IDE.

Key observations:
1. **Line ~42:** `enable.auto.commit=false` — we control when offsets commit
2. **Line ~55:** `consumer.poll(Duration.ofMillis(1000))` — 1 second poll timeout
3. **Line ~65:** `consumer.commitSync()` — commit only after processing
4. **Line ~60:** The comment about never logging full card numbers

---

### Step 2.3 — Lab: Add a New Field to the Producer

**Task:** Add a `country_code` field to the payment JSON.

Edit `PaymentProducer.java`, method `buildPaymentJson()`:

```java
static String buildPaymentJson(String txnId, int sequence) {
    String[] regions = {"US-EAST", "US-WEST", "EU-WEST", "AP-SOUTH"};
    String[] merchants = {"MERCH-001", "MERCH-002", "MERCH-003", "MERCH-004"};
    String[] countries = {"US", "US", "DE", "IN"};  // <-- ADD THIS
    double amount = 10.00 + (sequence % 500) * 1.37;
    String maskedCard = "****-****-****-" + String.format("%04d", (sequence % 9999) + 1);

    return String.format(
            "{\"transaction_id\":\"%s\","
          + "\"card_number_masked\":\"%s\","
          + "\"amount\":%.2f,"
          + "\"currency\":\"USD\","
          + "\"merchant_id\":\"%s\","
          + "\"country_code\":\"%s\","        // <-- ADD THIS
          + "\"timestamp\":%d,"
          + "\"status\":\"PENDING\","
          + "\"region\":\"%s\"}",
            txnId,
            maskedCard,
            amount,
            merchants[sequence % merchants.length],
            countries[sequence % countries.length],  // <-- ADD THIS
            Instant.now().toEpochMilli(),
            regions[sequence % regions.length]
    );
}
```

---

### Step 2.4 — Lab: Add a Filter to the Consumer

**Task:** Only log payments where `amount > 100.00`.

Edit `PaymentConsumer.java`, inside the forEach loop:

```java
records.forEach(record -> {
    // Simple amount filter
    String value = record.value();
    int amtIdx = value.indexOf("\"amount\":");
    if (amtIdx > 0) {
        String amtStr = value.substring(amtIdx + 9).split("[,}]")[0];
        double amount = Double.parseDouble(amtStr);

        if (amount > 100.00) {
            log.info("HIGH-VALUE payment: partition={} offset={} amount={} key={}",
                    record.partition(), record.offset(), amount, record.key());
        }
    }
});
```

---

### Step 2.5 — Rebuild and Verify

```bash
# Rebuild
mvn clean package -DskipTests

# Run the producer (Terminal 1)
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     produce

# Run the consumer (Terminal 2)
java -Dapp.env=dev \
     -jar producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar \
     consume
```

**Observe:** The consumer now only logs payments above 100.00.

Use kcat to verify the new `country_code` field:

```bash
kcat -b localhost:9092 -t payments -C -o -1 -c 1 -e
```

---

### Step 2.6 — Run Unit Tests

```bash
mvn test -pl producer-consumer-app
```

Expected: All tests pass.

> **Note:** If your changes broke a test, fix it! The tests verify PCI-DSS compliance (masked card numbers).

---

### Step 2.7 — Checkpoint!

```bash
./scripts/workshop-check.sh block2
```

```
  >>> SILBERNER SPORN EARNED! <<<
```

---

## Block 3 — Kafka Streams: Fraud Detection

### Goal: Earn the **Goldener Sporn**

---

### Step 3.1 — Study the Topology

Open `kstreams-app/src/main/java/io/confluent/ps/kstreams/topology/FraudDetectionTopology.java`.

The pipeline:
1. **Read** from `payments` topic
2. **Enrich** each payment with a `risk_score` (0.0 to 1.0)
3. **Branch**: score > 0.7 goes to `fraud-alerts`, rest to `approved-payments`

Current rules:
| Rule | Condition | Score Added |
|---|---|---|
| High value | amount > 1000 | +0.4 |
| Very high value | amount > 5000 | +0.3 |
| Risky region | region = AP-SOUTH | +0.2 |
| Round amount | amount is round & > 500 | +0.15 |

---

### Step 3.2 — Study the Tests

Open `kstreams-app/src/test/java/io/confluent/ps/kstreams/topology/FraudDetectionTopologyTest.java`.

Key pattern with `TopologyTestDriver`:

```java
// Create test driver — no real broker needed!
Topology topology = FraudDetectionTopology.build(props);
testDriver = new TopologyTestDriver(topology, props);

// Create virtual topics
inputTopic = testDriver.createInputTopic("payments", ...);
fraudAlertsTopic = testDriver.createOutputTopic("fraud-alerts", ...);

// Feed data
inputTopic.pipeInput("txn-id", paymentJson);

// Assert results
assertFalse(fraudAlertsTopic.isEmpty());
```

---

### Step 3.3 — Lab: Add a Velocity Check Rule

**Task:** Add a rule that flags transactions over 3000 from merchant MERCH-004.

Edit `FraudDetectionTopology.java`, method `computeRiskScore()`:

```java
static double computeRiskScore(double amount, String paymentJson) {
    double score = 0.0;

    // Rule 1: High-value transactions
    if (amount > HIGH_VALUE_THRESHOLD) score += 0.4;
    if (amount > 5000.00) score += 0.3;

    // Rule 2: High-risk regions
    if (paymentJson.contains("\"region\":\"AP-SOUTH\"")) score += 0.2;

    // Rule 3: Round amounts
    if (amount == Math.floor(amount) && amount > 500) score += 0.15;

    // NEW Rule 4: Suspicious merchant + high value
    if (amount > 3000.00 && paymentJson.contains("\"merchant_id\":\"MERCH-004\"")) {
        score += 0.35;
    }

    return Math.min(score, 1.0);
}
```

---

### Step 3.4 — Lab: Write a Test for the New Rule

Add this test to `FraudDetectionTopologyTest.java`:

```java
@Test
void highValue_suspiciousMerchant_shouldBeFlagged() {
    // amount=3500 > 3000 -> +0.35 (new rule) + amount>1000 -> +0.4 = 0.75 > 0.7
    String payment = "{\"transaction_id\":\"txn-velocity\","
            + "\"card_number_masked\":\"****-****-****-5555\","
            + "\"amount\":3500.00,"
            + "\"currency\":\"USD\","
            + "\"merchant_id\":\"MERCH-004\","
            + "\"timestamp\":1700000000000,"
            + "\"status\":\"PENDING\","
            + "\"region\":\"US-EAST\"}";

    inputTopic.pipeInput("txn-velocity", payment);

    assertFalse(fraudAlertsTopic.isEmpty(),
            "High-value txn from suspicious merchant should trigger alert");
}
```

---

### Step 3.5 — Run Tests and the Full App

```bash
# Run all KStreams tests (should be 9 now — 8 original + 1 new)
mvn test -pl kstreams-app

# Rebuild
mvn clean package -DskipTests

# Make sure the producer is running (Terminal 1)
# Then start the KStreams app (Terminal 3)
java -Dapp.env=dev \
     -jar kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar
```

Use kcat to check the output topics:

```bash
# Fraud alerts
kcat -b localhost:9092 -t fraud-alerts -C -o beginning -c 5 -e

# Approved payments
kcat -b localhost:9092 -t approved-payments -C -o beginning -c 5 -e
```

---

### Step 3.6 — Checkpoint!

```bash
./scripts/workshop-check.sh block3
```

```
  >>> GOLDENER SPORN EARNED! <<<
```

---

## Block 4 — Configuration & Git-Flow

### Goal: Earn the **Eiserner Sporn**

---

### Step 4.1 — Test the Configuration Layers

**Layer 1+2 (classpath):**
```bash
# Default dev config — uses localhost:9092
java -Dapp.env=dev -jar producer-consumer-app/target/*.jar produce
# Check the log: "bootstrap.servers='localhost:9092'"
```

Stop it (Ctrl+C), then try:

**Layer 5 (environment variable):**
```bash
export KAFKA_BOOTSTRAP_SERVERS="my-custom-broker:19092"
java -Dapp.env=dev -jar producer-consumer-app/target/*.jar produce
# Check the log: "bootstrap.servers='my-custom-broker:19092'"
# (It will fail to connect — that's expected! We're just testing the override.)
```

Stop it (Ctrl+C), unset the variable:
```bash
unset KAFKA_BOOTSTRAP_SERVERS
```

**Layer 3 (external file):**
```bash
echo "bootstrap.servers=file-override:9092" > /tmp/my-config.properties
java -Dapp.env=dev -Dconfig.file=/tmp/my-config.properties \
     -jar producer-consumer-app/target/*.jar produce
# Check the log: "bootstrap.servers='file-override:9092'"
```

---

### Step 4.2 — Compare Environment Configs

Look at the differences between environments:

```bash
diff producer-consumer-app/src/main/resources/application-dev.properties \
     producer-consumer-app/src/main/resources/application-prod.properties
```

Key differences:
- DEV: `localhost:9092`, no security
- PROD: `${KAFKA_BOOTSTRAP_SERVERS}`, `SASL_SSL`, idempotence, `read_committed`

---

### Step 4.3 — Practice Git-Flow

```bash
# Create a feature branch from current state
git checkout -b feature/workshop-changes

# Stage and commit your changes from Blocks 2 and 3
git add producer-consumer-app/src/main/java/io/confluent/ps/producer/PaymentProducer.java
git add producer-consumer-app/src/main/java/io/confluent/ps/consumer/PaymentConsumer.java
git add kstreams-app/src/main/java/io/confluent/ps/kstreams/topology/FraudDetectionTopology.java
git add kstreams-app/src/test/java/io/confluent/ps/kstreams/topology/FraudDetectionTopologyTest.java

git commit -m "feat: add country_code, amount filter, and velocity fraud rule"
```

```bash
# Check your git log
git log --oneline -5
```

---

### Step 4.4 — Checkpoint!

```bash
git checkout -  # go back to previous branch
./scripts/workshop-check.sh block4
```

```
  >>> EISERNER SPORN EARNED! <<<
```

---

## Block 5 — Docker, Kubernetes & GitOps

### Goal: Earn the **Stahlerner Sporn**

---

### Step 5.1 — Build Docker Images

```bash
# Build the producer/consumer image
docker build -f docker/Dockerfile.producer-consumer \
  -t payment-app:workshop .

# Build the KStreams image
docker build -f docker/Dockerfile.kstreams \
  -t fraud-detection:workshop .
```

Verify the images:
```bash
docker images | grep -E "payment-app|fraud-detection"
```

---

### Step 5.2 — Run Containers

```bash
# Run the producer as a container
docker run --rm --network docker_default \
  -e APP_ENV=dev \
  -e KAFKA_BOOTSTRAP_SERVERS=broker:29092 \
  payment-app:workshop produce

# In another terminal, run the KStreams container
docker run --rm --network docker_default \
  -e APP_ENV=dev \
  -e KAFKA_BOOTSTRAP_SERVERS=broker:29092 \
  fraud-detection:workshop
```

> **Note:** We use `broker:29092` (Docker internal hostname), not `localhost:9092`.

---

### Step 5.3 — Explore Kustomize Overlays

```bash
# Render the DEV overlay — see what K8s would apply
kubectl kustomize k8s/overlays/dev/ 2>/dev/null || echo "(kubectl not connected — that's OK for this exercise)"

# Compare overlays by looking at the kustomization files
cat k8s/overlays/dev/kustomization.yaml
echo "---"
cat k8s/overlays/prod/kustomization.yaml
```

**Questions to answer:**
1. How many replicas does the fraud-detection app have in DEV vs PROD?
2. What are the resource limits in DEV vs PROD?
3. Where do the Kafka credentials come from?

---

### Step 5.4 — Study the CI/CD Pipelines

```bash
# Read the CI pipeline
cat .github/workflows/ci.yaml

# Read the CD pipeline
cat .github/workflows/cd-gitops.yaml
```

**Questions to answer:**
1. What triggers the CI pipeline?
2. When are Docker images built? (Which branches?)
3. How does the PROD deployment work? (Answer: PR with PCI-DSS checklist)

---

### Step 5.5 — Checkpoint!

```bash
./scripts/workshop-check.sh block5
```

```
  >>> STAHLERNER SPORN EARNED! <<<
```

---

## Block 6 — Troubleshooting & Diagnostics

### Goal: Earn the **Diamantener Sporn**

---

### Step 6.1 — Run Full Diagnostics

Make sure the local stack is running:
```bash
cd docker && docker compose up -d broker schema-registry && cd ..
```

Run the diagnostics toolkit:
```bash
./scripts/diagnose.sh full
```

Review every section of the output. Green = good, Yellow = warning, Red = problem.

---

### Step 6.2 — Scenario A: Broker Down

**Simulate the failure:**
```bash
docker compose -f docker/docker-compose.yml stop broker
```

**Diagnose:**
```bash
./scripts/diagnose.sh connectivity
```

Expected:
```
  [FAIL] Cannot reach broker at localhost:9092
```

**Fix:**
```bash
docker compose -f docker/docker-compose.yml start broker
```

**Verify:**
```bash
./scripts/diagnose.sh connectivity
```

Expected:
```
  [PASS] Broker reachable
```

---

### Step 6.3 — Scenario B: Consumer Lag

**Simulate the problem:**

1. Start the producer but **not** the consumer:
   ```bash
   java -Dapp.env=dev -jar producer-consumer-app/target/*.jar produce &
   ```

2. Wait 30 seconds for messages to pile up.

3. Check lag:
   ```bash
   ./scripts/diagnose.sh consumer-lag
   ```

   You should see LAG > 0 for all partitions.

4. **Fix** — start the consumer:
   ```bash
   java -Dapp.env=dev -jar producer-consumer-app/target/*.jar consume
   ```

5. Check lag again — it should be decreasing toward zero.

6. Stop producer and consumer (Ctrl+C or `kill %1`).

---

### Step 6.4 — Scenario C: Schema Registry

**Explore:**
```bash
./scripts/diagnose.sh schema-check
```

If the Schema Registry is empty (no subjects), that's OK for local dev.

**Test Schema Registration:**
```bash
# Register the payment schema
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.ps.model\",\"fields\":[{\"name\":\"transaction_id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' \
  http://localhost:8081/subjects/payments-value/versions

# Verify
curl -s http://localhost:8081/subjects | jq .
```

Now try an incompatible change (removing a field):
```bash
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.ps.model\",\"fields\":[{\"name\":\"transaction_id\",\"type\":\"string\"}]}"}' \
  http://localhost:8081/subjects/payments-value/versions
```

This should fail with a 409 error. **That's the expected behavior** — Schema Registry protects you from breaking changes.

---

### Step 6.5 — Checkpoint!

```bash
./scripts/workshop-check.sh block6
```

```
  >>> DIAMANTENER SPORN EARNED! <<<
```

---

## Workshop Complete!

If you've passed all 6 checkpoints:

```bash
./scripts/workshop-check.sh final
```

```
========================================
  MEISTER-SPORN EARNED!
  Congratulations — you are now a
  Confluent Cloud Java Developer!
========================================
```

### Clean Up

```bash
cd docker && docker compose down -v && cd ..
```

### Next Steps

1. Read the full [RUNBOOK.md](../../RUNBOOK.md) for reference
2. Set up your Confluent Cloud access with `./scripts/ccloud-setup.sh dev`
3. Start your first feature branch on a real project
4. Bookmark the RUNBOOK's Troubleshooting section for when you need it

---

> *"Sich die Sporen verdienen"* — You've earned your spurs. Now ride!
