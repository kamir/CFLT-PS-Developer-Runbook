# Lernpfad — Confluent Cloud Java Developer

> *"Earn Your Badges"*
> Earn your spurs on the path from apprentice to master.

---

## The Badges (Milestones)

Each Badge represents a skill level earned through hands-on practice.
Complete all 6 to earn the **Master Badge**.

```
                                    +------------------+
                                    |  MASTER BADGE   |
                                    |  Full mastery    |
                                    +--------+---------+
                                             |
                        +--------------------+--------------------+
                        |                                         |
               +--------+---------+                    +----------+--------+
               | DIAMOND BADGE|                    | STEEL BADGE  |
               | Troubleshooting  |                    | Docker & GitOps   |
               +--------+---------+                    +----------+--------+
                        |                                         |
               +--------+---------+                    +----------+--------+
               | IRON BADGE   |                    | GOLD BADGE    |
               | Config & GitFlow |                    | Kafka Streams     |
               +--------+---------+                    +----------+--------+
                        |                                         |
                        +--------------------+--------------------+
                                             |
                                    +--------+---------+
                                    | SILVER BADGE  |
                                    | Producer/Consumer|
                                    +--------+---------+
                                             |
                                    +--------+---------+
                                    | BRONZE BADGE  |
                                    | Local Dev Setup  |
                                    +------------------+
```

---

## Badge 1 — Bronze Badge

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

## Badge 2 — Silver Badge

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

## Badge 3 — Gold Badge

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

## Badge 4 — Iron Badge

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

## Badge 5 — Steel Badge

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

## Badge 6 — Diamond Badge

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

## Master Badge — Full Mastery

**Earned when:** All 6 Badges are validated.

```bash
./scripts/workshop-check.sh final
```

### What the Master Badge Certifies

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
|                    MASTER BADGE                                 |
|                                                                  |
|  This certifies that                                             |
|                                                                  |
|     _______________________________                              |
|                                                                  |
|  has successfully completed the Hands-On Workshop                |
|  and earned all 6 Badges:                                        |
|                                                                  |
|     Bronze Badge  - Local Development                         |
|     Silver Badge  - Producer/Consumer & PCI-DSS               |
|     Gold Badge   - Kafka Streams                             |
|     Iron Badge   - Configuration & Git-Flow                  |
|     Steel Badge - Docker, K8s & GitOps                      |
|     Diamond Badge - Troubleshooting                          |
|                                                                  |
|  Date: ________________    Instructor: ________________          |
|                                                                  |
+------------------------------------------------------------------+
```

---

---

## Advanced Levels — Beyond Master Badge

The learning path continues with three advanced levels. Each builds on all previous levels.

```
  Level 101 (1 day)      Level 201 (half day)     Level 301 (1 day)      Level 401 (1 day)
┌─────────────────┐   ┌──────────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│ Blocks 1–6      │   │ Blocks 7–10          │   │ Blocks 11–15    │   │ Blocks 16–19     │
│ 6 Badges        │──>│ 4 Badges             │──>│ 5 Badges        │──>│ 4 Badges         │
│ Master Badge   │   │ Tool Master     │   │ Workshop Master│  │ Grand Master     │
│                 │   │                      │   │                 │   │                  │
│ "Earn Your Badges│   │ "Know the Tools        │   │ "Master the Workshop  │   │ "Art of Optimization   │
│  Badges         │   │  kennen"             │   │  meistern"      │   │  Optimierung"    │
│  verdienen"     │   │                      │   │                 │   │                  │
└─────────────────┘   └──────────────────────┘   └─────────────────┘   └──────────────────┘
```

---

## Level 201 Badges — Know the Tools

| Block | Badge | Topic |
|---|---|---|
| 7 | **Smith Badge** | Make & Act — Build Automation |
| 8 | **Knight Badge** | kind & Helm — Local Kubernetes |
| 9 | **Inspector Badge** | k6, ngrok & Shadow Traffic — Testing |
| 10 | **Messenger Badge** | Confluent CLI, Kafka CLI & kcat — Mastery |

**Completion:** Tool Master (Tool Master)

See full details: `docs/workshop/LEVEL-201.md`

---

## Level 301 Badges — Master the Workshop

| Block | Badge | Topic |
|---|---|---|
| 11 | **Pipeline Badge** | CI/CD Pipeline Engineering with Make & Act |
| 12 | **Strategist Badge** | K8s Deployment Strategy (kind + Helm + Kustomize) |
| 13 | **Load Tester Badge** | Load Testing & Traffic Management (k6 + Shadow) |
| 14 | **Commander Badge** | Confluent Cloud Automation & Operational Runbooks |
| 15 | **General Badge** | End-to-End Release Simulation |

**Completion:** Workshop Master (Workshop Master)

See full details: `docs/workshop/LEVEL-301.md`

---

## Level 401 Badges — Art of Optimization

| Block | Badge | Topic |
|---|---|---|
| 16 | **Tuner Badge** | Producer & Consumer Throughput Tuning |
| 17 | **Engineer Badge** | Kafka Streams & RocksDB Optimization |
| 18 | **Architect Badge** | K8s Resource Tuning & JVM Optimization |
| 19 | **Field Marshal Badge** | Production Load Testing & Capacity Planning |

**Completion:** Grand Master (Grand Master)

See full details: `docs/workshop/LEVEL-401.md`

---

## Complete Badges Summary

```
Level 101:  Bronze → Silver → Gold → Iron → Steel → Diamond  = Master Badge
Level 201:  Smith → Knight → Inspector → Messenger                                       = Tool Master
Level 301:  Pipeline → Strategist → Load Tester → Commander → General                  = Workshop Master
Level 401:  Tuner → Engineer → Architect → Field Marshal                                  = Grand Master

Total: 19 Blocks | 17 Badges | 4 Mastery Levels | 3.5 Days
```

---

## Continuing Education

After earning the Grand Master, deepen your skills:

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
