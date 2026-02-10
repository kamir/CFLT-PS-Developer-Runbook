# Lernpfad — Confluent Cloud Java Developer

> *"Sich die Sporen verdienen"*
> Earn your spurs on the path from apprentice to master.

---

## The Sporen (Milestones)

Each Sporn represents a skill level earned through hands-on practice.
Complete all 6 to earn the **Meister-Sporn**.

```
                                    +------------------+
                                    |  MEISTER-SPORN   |
                                    |  Full mastery    |
                                    +--------+---------+
                                             |
                        +--------------------+--------------------+
                        |                                         |
               +--------+---------+                    +----------+--------+
               | DIAMANTENER SPORN|                    | STAHLERNER SPORN  |
               | Troubleshooting  |                    | Docker & GitOps   |
               +--------+---------+                    +----------+--------+
                        |                                         |
               +--------+---------+                    +----------+--------+
               | EISERNER SPORN   |                    | GOLDENER SPORN    |
               | Config & GitFlow |                    | Kafka Streams     |
               +--------+---------+                    +----------+--------+
                        |                                         |
                        +--------------------+--------------------+
                                             |
                                    +--------+---------+
                                    | SILBERNER SPORN  |
                                    | Producer/Consumer|
                                    +--------+---------+
                                             |
                                    +--------+---------+
                                    | BRONZENER SPORN  |
                                    | Local Dev Setup  |
                                    +------------------+
```

---

## Sporn 1 — Bronzener Sporn (Bronze)

**Topic:** Local Development Environment & First Messages

### Skills Demonstrated

- [ ] Start local Kafka cluster with docker-compose
- [ ] Create topics using the provisioning script
- [ ] Build the project with Maven
- [ ] Run the payment producer and observe messages
- [ ] Run the payment consumer and see delivery
- [ ] Use kcat to inspect topic contents manually

### Validation Criteria

```bash
./scripts/workshop-check.sh block1
```

| Check | Criteria |
|---|---|
| Docker containers | broker and schema-registry running |
| Topics | payments, fraud-alerts, approved-payments exist |
| Messages | At least 1 message in the payments topic |

### Knowledge Check Questions

1. What port does the local Kafka broker listen on?
2. How many partitions does the `payments` topic have?
3. What format are the messages in? (JSON / Avro / Protobuf)
4. Where is the card number stored in the message? Is it full or masked?

---

## Sporn 2 — Silberner Sporn (Silver)

**Topic:** Producer/Consumer Deep Dive & PCI-DSS Compliance

### Skills Demonstrated

- [ ] Explain the purpose of `acks=all` and `enable.idempotence=true`
- [ ] Understand why manual offset commit is preferred over auto-commit
- [ ] Identify where card number masking happens in the code
- [ ] Add a new field to the producer output
- [ ] Add a processing filter to the consumer
- [ ] Run unit tests and verify they pass

### Validation Criteria

```bash
./scripts/workshop-check.sh block2
```

| Check | Criteria |
|---|---|
| Build | Project compiles with modifications |
| Tests | All producer tests pass |
| PCI-DSS | Card numbers remain masked in output |

### Knowledge Check Questions

1. What happens if `acks=0`? Why is this dangerous for payment data?
2. Why do we use `enable.auto.commit=false`?
3. What PCI-DSS requirement does card masking address?
4. What is the difference between `commitSync()` and `commitAsync()`?

---

## Sporn 3 — Goldener Sporn (Gold)

**Topic:** Kafka Streams — Fraud Detection Topology

### Skills Demonstrated

- [ ] Read and understand a Kafka Streams topology
- [ ] Explain the branching logic (fraud-alerts vs. approved-payments)
- [ ] Add a new fraud detection rule to the risk scoring engine
- [ ] Write a test using TopologyTestDriver (no broker needed)
- [ ] Run the KStreams app and observe real-time branching

### Validation Criteria

```bash
./scripts/workshop-check.sh block3
```

| Check | Criteria |
|---|---|
| New rule | Velocity check rule added to computeRiskScore() |
| Test | New test case for the velocity rule passes |
| All tests | All 9 topology tests pass (8 original + 1 new) |

### Knowledge Check Questions

1. What is a KStream vs. a KTable? When would you use each?
2. What does `TopologyTestDriver` replace? Why is it valuable?
3. What happens to the KStreams state store if a pod restarts?
4. What does `processing.guarantee=exactly_once_v2` mean?

---

## Sporn 4 — Eiserner Sporn (Iron)

**Topic:** Configuration Management & Git-Flow

### Skills Demonstrated

- [ ] Explain the 5-layer config resolution order
- [ ] Override configuration via environment variables
- [ ] Override configuration via an external properties file
- [ ] Create a Git feature branch and commit changes
- [ ] Understand the Git-Flow branching model (feature/release/hotfix)
- [ ] Explain the difference between DEV, QA, and PROD config

### Validation Criteria

```bash
./scripts/workshop-check.sh block4
```

| Check | Criteria |
|---|---|
| Config override | Demonstrated env var and file overrides |
| Feature branch | Created and committed to a feature branch |
| Understanding | Can explain config differences across environments |

### Knowledge Check Questions

1. In what order does ConfigLoader apply overrides? Which wins?
2. Why are secrets stored as `${PLACEHOLDER}` in QA/PROD configs?
3. What is the difference between `develop` and `release/*` branches?
4. Who approves PROD deployments? Why? (PCI-DSS Req 6.4)

---

## Sporn 5 — Stahlerner Sporn (Steel)

**Topic:** Docker, Kubernetes & GitOps Deployment

### Skills Demonstrated

- [ ] Build multi-stage Docker images for both applications
- [ ] Explain PCI-DSS hardening in the Dockerfile (non-root, minimal image)
- [ ] Render Kustomize overlays for dev, qa, and prod
- [ ] Identify differences in K8s manifests across environments
- [ ] Read and understand the CI/CD pipeline definitions
- [ ] Explain the GitOps deployment flow (PR-based PROD promotion)

### Validation Criteria

```bash
./scripts/workshop-check.sh block5
```

| Check | Criteria |
|---|---|
| Docker images | Both images built successfully |
| Image security | Images run as non-root user |
| K8s manifests | Can render overlays for all environments |

### Knowledge Check Questions

1. Why do we use multi-stage Docker builds?
2. What does the K8s NetworkPolicy restrict? (PCI-DSS Req 1)
3. How does the PROD deployment PR get created? Who approves it?
4. What is the purpose of Kustomize overlays vs. a single manifest?

---

## Sporn 6 — Diamantener Sporn (Diamond)

**Topic:** Troubleshooting & Diagnostics

### Skills Demonstrated

- [ ] Run the full diagnostics script and interpret all output
- [ ] Diagnose and fix a broker connectivity issue
- [ ] Diagnose and resolve consumer lag
- [ ] Understand schema compatibility errors
- [ ] Know which JMX metrics to monitor in production

### Validation Criteria

```bash
./scripts/workshop-check.sh block6
```

| Check | Criteria |
|---|---|
| Scenario A | Broker stopped, diagnosed, and restarted |
| Scenario B | Consumer lag observed and resolved |
| Scenario C | Schema Registry explored and tested |

### Knowledge Check Questions

1. What is the first thing you check when a producer gets `TimeoutException`?
2. How do you reduce consumer lag? What limits the number of consumers?
3. What Avro schema changes are backward-compatible?
4. What JMX metric tells you a KStreams thread has died?

---

## Meister-Sporn — Full Mastery

**Earned when:** All 6 Sporen are validated.

```bash
./scripts/workshop-check.sh final
```

### What the Meister-Sporn Certifies

The holder can:
1. Set up and operate a local Kafka development environment
2. Build PCI-DSS compliant Java producers and consumers
3. Design and test Kafka Streams topologies
4. Manage configuration across DEV, QA, and PROD environments
5. Containerize and deploy applications via GitOps
6. Troubleshoot common Kafka issues in production

### Certificate

```
+------------------------------------------------------------------+
|                                                                  |
|              CONFLUENT CLOUD JAVA DEVELOPER                      |
|                    MEISTER-SPORN                                 |
|                                                                  |
|  This certifies that                                             |
|                                                                  |
|     _______________________________                              |
|                                                                  |
|  has successfully completed the Hands-On Workshop                |
|  and earned all 6 Sporen:                                        |
|                                                                  |
|     Bronzener Sporn  - Local Development                         |
|     Silberner Sporn  - Producer/Consumer & PCI-DSS               |
|     Goldener Sporn   - Kafka Streams                             |
|     Eiserner Sporn   - Configuration & Git-Flow                  |
|     Stahlerner Sporn - Docker, K8s & GitOps                      |
|     Diamantener Sporn - Troubleshooting                          |
|                                                                  |
|  Date: ________________    Instructor: ________________          |
|                                                                  |
+------------------------------------------------------------------+
```

---

---

## Advanced Levels — Beyond Meister-Sporn

The learning path continues with three advanced levels. Each builds on all previous levels.

```
  Level 101 (1 day)      Level 201 (half day)     Level 301 (1 day)      Level 401 (1 day)
┌─────────────────┐   ┌──────────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│ Blocks 1–6      │   │ Blocks 7–10          │   │ Blocks 11–15    │   │ Blocks 16–19     │
│ 6 Sporen        │──>│ 4 Sporen             │──>│ 5 Sporen        │──>│ 4 Sporen         │
│ Meister-Sporn   │   │ Werkzeug-Meister     │   │ Werkstatt-Meister│  │ Grossmeister     │
│                 │   │                      │   │                 │   │                  │
│ "Sich die       │   │ "Das Werkzeug        │   │ "Die Werkstatt  │   │ "Die Kunst der   │
│  Sporen         │   │  kennen"             │   │  meistern"      │   │  Optimierung"    │
│  verdienen"     │   │                      │   │                 │   │                  │
└─────────────────┘   └──────────────────────┘   └─────────────────┘   └──────────────────┘
```

---

## Level 201 Sporen — Das Werkzeug kennen

| Block | Sporn | Topic |
|---|---|---|
| 7 | **Schmied-Sporn** (Blacksmith) | Make & Act — Build Automation |
| 8 | **Ritter-Sporn** (Knight) | kind & Helm — Local Kubernetes |
| 9 | **Prüfer-Sporn** (Inspector) | k6, ngrok & Shadow Traffic — Testing |
| 10 | **Melder-Sporn** (Herald) | Confluent CLI, Kafka CLI & kcat — Mastery |

**Completion:** Werkzeug-Meister (Tool Master)

See full details: `docs/workshop/LEVEL-201.md`

---

## Level 301 Sporen — Die Werkstatt meistern

| Block | Sporn | Topic |
|---|---|---|
| 11 | **Pipeline-Sporn** | CI/CD Pipeline Engineering with Make & Act |
| 12 | **Strategen-Sporn** | K8s Deployment Strategy (kind + Helm + Kustomize) |
| 13 | **Lastprüfer-Sporn** | Load Testing & Traffic Management (k6 + Shadow) |
| 14 | **Kommandant-Sporn** | Confluent Cloud Automation & Operational Runbooks |
| 15 | **General-Sporn** | End-to-End Release Simulation |

**Completion:** Werkstatt-Meister (Workshop Master)

See full details: `docs/workshop/LEVEL-301.md`

---

## Level 401 Sporen — Die Kunst der Optimierung

| Block | Sporn | Topic |
|---|---|---|
| 16 | **Tuner-Sporn** | Producer & Consumer Throughput Tuning |
| 17 | **Ingenieur-Sporn** | Kafka Streams & RocksDB Optimization |
| 18 | **Architekt-Sporn** | K8s Resource Tuning & JVM Optimization |
| 19 | **Feldherr-Sporn** | Production Load Testing & Capacity Planning |

**Completion:** Grossmeister (Grand Master)

See full details: `docs/workshop/LEVEL-401.md`

---

## Complete Sporen Summary

```
Level 101:  Bronzener → Silberner → Goldener → Eiserner → Stahlerner → Diamantener  = Meister-Sporn
Level 201:  Schmied → Ritter → Prüfer → Melder                                       = Werkzeug-Meister
Level 301:  Pipeline → Strategen → Lastprüfer → Kommandant → General                  = Werkstatt-Meister
Level 401:  Tuner → Ingenieur → Architekt → Feldherr                                  = Grossmeister

Total: 19 Blocks | 17 Sporen | 4 Mastery Levels | 3.5 Days
```

---

## Continuing Education

After earning the Grossmeister, deepen your skills:

| Topic | Resource |
|---|---|
| Confluent Certified Developer | [training.confluent.io](https://training.confluent.io) |
| Kafka Streams in Depth | Kafka Streams Developer Guide |
| Schema Evolution Patterns | Confluent Schema Registry docs |
| K8s Operators for Kafka | Confluent for Kubernetes (CFK) |
| Advanced PCI-DSS | PCI SSC Document Library |
| RocksDB Tuning Guide | [github.com/facebook/rocksdb/wiki/RocksDB-Tuning-Guide](https://github.com/facebook/rocksdb/wiki/RocksDB-Tuning-Guide) |
| k6 Documentation | [k6.io/docs](https://k6.io/docs/) |
| Helm Best Practices | [helm.sh/docs/chart_best_practices](https://helm.sh/docs/chart_best_practices/) |
