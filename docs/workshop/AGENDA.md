# Hands-On Workshop — Confluent Cloud Java Developer Toolkit

## Workshop Agenda

> **Title:** "Von der ersten Zeile bis zur Produktion"
> *(From the First Line to Production)*
>
> **Duration:** Full day (6h net, 8h with breaks)
> **Audience:** Java developers, DevOps engineers, Tech Leads
> **Prerequisites:** JDK 17, Maven, Docker Desktop, Git, IDE installed

---

## Schedule at a Glance

| Time | Block | Topic | Sporn |
|---|---|---|---|
| 09:00 – 09:30 | **Opening** | Welcome, objectives, architecture overview | — |
| 09:30 – 10:15 | **Block 1** | Local Dev Environment & First Messages | Bronzener Sporn |
| 10:15 – 10:30 | *Break* | *Kaffee & Kuchen* | |
| 10:30 – 11:30 | **Block 2** | Producer/Consumer Deep Dive & PCI-DSS | Silberner Sporn |
| 11:30 – 12:30 | **Block 3** | Kafka Streams — Fraud Detection Topology | Goldener Sporn |
| 12:30 – 13:30 | *Lunch* | *Mittagspause* | |
| 13:30 – 14:30 | **Block 4** | Configuration, Environments & Git-Flow | Eiserner Sporn |
| 14:30 – 14:45 | *Break* | *Kaffeepause* | |
| 14:45 – 15:45 | **Block 5** | Docker, Kubernetes & GitOps Deployment | Stählerner Sporn |
| 15:45 – 16:30 | **Block 6** | Troubleshooting & Diagnostics | Diamantener Sporn |
| 16:30 – 17:00 | **Closing** | Recap, Q&A, Zertifikat | Meister-Sporn |

---

## Detailed Agenda

### 09:00 – 09:30 | Opening

**Instructor-led (30 min)**

- Welcome & introductions
- Workshop objectives and ground rules
- Architecture overview: Payment Pipeline on Confluent Cloud
- The 3 environments: DEV (manual) → QA (scripted) → PROD (GitOps)
- PCI-DSS: Why it matters for our pipeline
- Tour of the repository structure

**Slides:** Deck sections 1–4

---

### 09:30 – 10:15 | Block 1 — Local Dev Environment & First Messages

**Hands-on (45 min)** | Earn: **Bronzener Sporn** (Bronze Spur)

Participants set up the local environment from scratch and send their first Kafka messages.

| Step | Task | Time |
|---|---|---|
| 1.1 | Clone the repo, inspect the structure | 5 min |
| 1.2 | Start docker-compose (broker + Schema Registry) | 5 min |
| 1.3 | Create topics with `create-topics.sh` | 5 min |
| 1.4 | Build the project with Maven | 10 min |
| 1.5 | Run the producer — observe messages flowing | 5 min |
| 1.6 | Run the consumer — see messages arrive | 5 min |
| 1.7 | Use `kcat` to inspect topics manually | 5 min |
| **Check** | **Validate: 100+ messages produced & consumed** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block1`

---

### 10:30 – 11:30 | Block 2 — Producer/Consumer Deep Dive & PCI-DSS

**Instructor-led + Hands-on (60 min)** | Earn: **Silberner Sporn** (Silver Spur)

Deep dive into the producer and consumer code with PCI-DSS focus.

| Step | Task | Time |
|---|---|---|
| 2.1 | **[Slides]** Producer internals: acks, idempotence, retries | 10 min |
| 2.2 | Walk through `PaymentProducer.java` — card masking | 5 min |
| 2.3 | **[Lab]** Modify the producer: add a new field to the payment | 10 min |
| 2.4 | **[Slides]** Consumer internals: offsets, commit strategies | 10 min |
| 2.5 | Walk through `PaymentConsumer.java` — manual commit | 5 min |
| 2.6 | **[Lab]** Add a processing filter in the consumer | 10 min |
| 2.7 | Run `PaymentProducerTest` — understand assertions | 5 min |
| **Check** | **Validate: modified producer running, tests green** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block2`

---

### 11:30 – 12:30 | Block 3 — Kafka Streams: Fraud Detection

**Instructor-led + Hands-on (60 min)** | Earn: **Goldener Sporn** (Gold Spur)

Build and test a real Kafka Streams topology.

| Step | Task | Time |
|---|---|---|
| 3.1 | **[Slides]** KStreams architecture: topology, state stores, threading | 10 min |
| 3.2 | Walk through `FraudDetectionTopology.java` | 10 min |
| 3.3 | **[Lab]** Add a new fraud rule (velocity check) | 15 min |
| 3.4 | **[Lab]** Write a test for the new rule using `TopologyTestDriver` | 10 min |
| 3.5 | Run the full KStreams app, observe branching (alerts vs. approved) | 10 min |
| **Check** | **Validate: new rule working, all tests pass** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block3`

---

### 13:30 – 14:30 | Block 4 — Configuration, Environments & Git-Flow

**Instructor-led + Hands-on (60 min)** | Earn: **Eiserner Sporn** (Iron Spur)

Master the configuration system and Git-Flow workflow.

| Step | Task | Time |
|---|---|---|
| 4.1 | **[Slides]** ConfigLoader: 5-layer resolution order | 10 min |
| 4.2 | **[Lab]** Override config via env vars, system props, external file | 10 min |
| 4.3 | **[Slides]** Git-Flow: branches, merging, release process | 10 min |
| 4.4 | **[Lab]** Create a feature branch, make a change, open a PR | 15 min |
| 4.5 | **[Lab]** Simulate a release branch and version bump | 10 min |
| **Check** | **Validate: config overrides working, PR created** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block4`

---

### 14:45 – 15:45 | Block 5 — Docker, Kubernetes & GitOps

**Instructor-led + Hands-on (60 min)** | Earn: **Stählerner Sporn** (Steel Spur)

Containerize, deploy to K8s, and understand the GitOps flow.

| Step | Task | Time |
|---|---|---|
| 5.1 | **[Slides]** Docker multi-stage builds, non-root, PCI-DSS hardening | 10 min |
| 5.2 | **[Lab]** Build Docker images locally | 10 min |
| 5.3 | **[Slides]** K8s manifests: Kustomize, overlays, NetworkPolicy | 10 min |
| 5.4 | **[Lab]** Apply the dev overlay, inspect manifests with `kubectl diff` | 10 min |
| 5.5 | **[Slides]** GitOps: CI/CD pipelines, PROD promotion PRs | 10 min |
| 5.6 | **[Lab]** Walk through `.github/workflows/` and trace a deployment | 5 min |
| **Check** | **Validate: Docker images built, K8s manifests rendered** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block5`

---

### 15:45 – 16:30 | Block 6 — Troubleshooting & Diagnostics

**Hands-on (45 min)** | Earn: **Diamantener Sporn** (Diamond Spur)

Diagnose real problems using the toolkit.

| Step | Task | Time |
|---|---|---|
| 6.1 | Run `./scripts/diagnose.sh full` — interpret all output | 10 min |
| 6.2 | **[Scenario]** Broker unreachable — find and fix the issue | 10 min |
| 6.3 | **[Scenario]** Consumer lag growing — diagnose and resolve | 10 min |
| 6.4 | **[Scenario]** Schema compatibility error — fix the schema | 10 min |
| **Check** | **Validate: all 3 scenarios resolved** | 5 min |

**Checkpoint:** Run `./scripts/workshop-check.sh block6`

---

### 16:30 – 17:00 | Closing

**Instructor-led (30 min)**

- Recap of all 6 blocks
- Review of earned Sporen (learning track progress)
- Q&A session
- Distribution of workshop certificates
- Next steps: Confluent Cloud access, team onboarding, PROD readiness

**Slide:** Final "Meister-Sporn" certificate slide

---

## Instructor Preparation Checklist

- [ ] Docker Desktop running on all participant machines
- [ ] JDK 17 + Maven 3.9 installed
- [ ] kcat/kafkacat installed
- [ ] Repository cloned to all machines
- [ ] `docker pull confluentinc/cp-kafka:7.7.0` pre-pulled (avoids slow WiFi)
- [ ] `docker pull confluentinc/cp-schema-registry:7.7.0` pre-pulled
- [ ] Print participant handout (HANDS-ON-LAB.md)
- [ ] Projector / screen sharing set up
- [ ] Whiteboard or Miro board for architecture diagrams

---

## Materials

| Document | File | Purpose |
|---|---|---|
| This Agenda | `docs/workshop/AGENDA.md` | Workshop schedule and structure |
| Slide Deck | `docs/workshop/DECK.md` | Instructor presentation (Marp) |
| Lab Guide | `docs/workshop/HANDS-ON-LAB.md` | Step-by-step participant guide |
| Learning Track | `docs/workshop/LERNPFAD.md` | Sporen milestones and badges |
| Tool Reference | `docs/workshop/TOOLS.md` | Complete tool documentation |
| Validation Script | `scripts/workshop-check.sh` | Automated checkpoint validation |

---

## Advanced Levels

This agenda covers **Level 101** (Blocks 1–6). The full curriculum continues:

| Level | Document | Duration | Focus |
|---|---|---|---|
| **101** | This agenda (Blocks 1–6) | 1 day | Foundations — build, run, deploy |
| **201** | `docs/workshop/LEVEL-201.md` (Blocks 7–10) | Half day | Tool introduction — Make, Act, kind, Helm, k6, kcat mastery |
| **301** | `docs/workshop/LEVEL-301.md` (Blocks 11–15) | 1 day | Deep dive — CI/CD engineering, K8s strategy, release simulation |
| **401** | `docs/workshop/LEVEL-401.md` (Blocks 16–19) | 1 day | Engineering — RocksDB tuning, JVM optimization, capacity planning |

**Total curriculum:** 3.5 days | 19 blocks | 17 Sporen | 1 Grossmeister
