# Progress Tracker - John Doe (EXAMPLE)

> **NOTE**: This is an example filled-out progress tracker to show students how to complete theirs.
> Students should copy `PROGRESS_TRACKER_TEMPLATE.md` and create their own personalized version.

**GitHub Username**: johndoe
**Branch**: student/johndoe
**Start Date**: 2026-02-03
**Target Level**: 101-301 (skip 401 for now)
**Trainer**: Alice Smith
**Cohort/Workshop**: February 2026 Cohort

---

## 🎯 Learning Goals

**What I want to achieve from this workshop**:
- Build production-ready Kafka applications with Java
- Understand how to deploy Kafka apps to Kubernetes
- Learn best practices for CI/CD with Kafka

**Specific skills I want to master**:
- Kafka Streams for real-time processing
- Docker containerization with multi-stage builds
- Kubernetes deployment strategies

**How I'll apply this knowledge**:
- Migrate our legacy batch ETL to real-time streaming
- Set up CI/CD pipeline for our microservices
- Help team adopt Kafka for event-driven architecture

---

## 📊 Overall Progress

| Level | Status | Start Date | Completion Date | Badge Earned |
|-------|--------|------------|-----------------|--------------|
| 101 - Foundations | ✅ Complete | 2026-02-03 | 2026-02-03 | ✅ Master Badge |
| 201 - Tool Mastery | ✅ Complete | 2026-02-04 | 2026-02-04 | ✅ Tool Master |
| 301 - Engineering | 🔄 In Progress | 2026-02-05 | | ⬜ Workshop Master |
| 401 - Optimization | ⬜ Not Started | | | ⬜ Grand Master |

---

## 📚 Level 101: Foundations

**Overall Status**: ✅ Complete
**Master Badge**: ✅ Earned (2026-02-03)

### Block 1: Bronze Badge 🥉
**Topic**: Local Dev Environment & First Messages
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 1 hour

**What I Learned**:
- Docker Compose makes it easy to run Kafka locally
- Topics are the fundamental abstraction in Kafka
- kcat is super useful for quick message inspection
- Partitions allow parallelism in message processing

**Exercises Completed**:
- [x] Set up local Docker environment
- [x] Start Kafka broker and Schema Registry
- [x] Create first topic (`test-topic`)
- [x] Produce first message with kcat
- [x] Consume messages from topic

**Challenges**:
- Initially Docker wasn't starting - had to restart Docker Desktop
- Confused about partition vs offset at first

**Solutions Found**:
- Restarted Docker Desktop, waited for it to fully initialize
- Trainer explained: partition = which queue, offset = position in that queue
- Visualized it as multiple lanes (partitions) on a highway

**Code Commits**:
- `a3f1b92` - Initial local-up successful, broker running
- `b4e2c83` - First kcat produce/consume test successful

**Notes**:
- kcat format string is powerful: `-f 'Partition:%p Offset:%o Key:%k Value:%s\n'`
- Always check `docker ps` before assuming Kafka is running
- Port 9092 for broker, 8081 for Schema Registry

**Knowledge Check**:
- [x] Can explain what a Kafka topic is: "Named stream of events/messages"
- [x] Can explain partitions and offsets: "Partitions = parallel queues, offsets = sequence number"
- [x] Can produce and consume messages with kcat

---

### Block 2: Silver Badge 🥈
**Topic**: Producer/Consumer Deep Dive & PCI-DSS Compliance
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 2 hours

**What I Learned**:
- Card masking is critical for PCI-DSS compliance (only store last 4 digits)
- Producer acks=all ensures durability (but impacts latency)
- enable.idempotence=true prevents duplicates during retries
- Manual offset commits give you control over at-least-once delivery
- Consumer groups allow horizontal scaling

**Exercises Completed**:
- [x] Implement PaymentProducer with Avro schema
- [x] Add PCI-DSS card masking logic
- [x] Configure producer acks and idempotence
- [x] Implement PaymentConsumer
- [x] Add manual offset commit handling
- [x] Test producer/consumer flow

**Challenges**:
- Regex for card masking was tricky - kept getting the pattern wrong
- Initially forgot to commit offsets manually, causing duplicate processing
- Avro schema compatibility errors when I changed field types

**Solutions Found**:
- Used this regex pattern: `replaceAll("\\d{4}(?=\\d{4})", "****")` for masking
- Moved offset commit to AFTER successful processing
- Learned about schema evolution: can add optional fields, but can't change types

**Code Commits**:
- `c5f3d94` - Implement PaymentProducer with Avro serialization
- `d6g4e05` - Add PCI-DSS compliant card masking (****-****-****-1234 format)
- `e7h5f16` - Implement PaymentConsumer with manual offset commit
- `f8i6g27` - Add error handling for malformed messages
- `g9j7h38` - Unit tests for card masking validation

**Notes**:
- acks=all: Leader AND all ISRs must acknowledge
- enable.idempotence=true: Broker deduplicates based on sequence number
- Don't commit offset until you're SURE processing succeeded
- Avro requires Schema Registry for serialization/deserialization
- PCI-DSS: Never store full card number, CVV, or PIN

**Knowledge Check**:
- [x] Understand producer acks (0, 1, all): "0=fire-and-forget, 1=leader only, all=full replication"
- [x] Can explain idempotence and why it matters: "Prevents duplicates on retry, safe to retry"
- [x] Understand consumer groups and offset management: "Multiple consumers, shared offset, each partition to one consumer"
- [x] Can implement PCI-DSS compliant card masking: "Mask all but last 4 digits"

---

### Block 3: Gold Badge 🥇
**Topic**: Kafka Streams Topology & Fraud Detection
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 2.5 hours

**What I Learned**:
- Kafka Streams is a Java library (not a separate cluster!)
- Topology is a DAG (directed acyclic graph) of processing nodes
- Branching allows you to split streams based on predicates
- TopologyTestDriver lets you test without running Kafka
- State stores are backed by RocksDB (persistent key-value store)

**Exercises Completed**:
- [x] Build Kafka Streams topology
- [x] Implement KStream branching logic (high-risk vs low-risk)
- [x] Add fraud detection rules (amount > $10,000 = high risk)
- [x] Write TopologyTestDriver tests
- [x] Test with local broker

**Challenges**:
- Topology visualization was confusing at first
- Branch syntax changed in recent Kafka versions
- TopologyTestDriver test data setup was verbose
- State store wasn't persisting between restarts (realized it was expected for testing)

**Solutions Found**:
- Drew out topology on paper: payments → filter → branch → [fraud-alerts, approved-payments]
- Used new branching syntax: `stream.split(Named.as("branch-")).branch(...)`
- Created helper methods for TopologyTestDriver test data creation
- Learned: TopologyTestDriver uses in-memory stores by default

**Code Commits**:
- `h0k8i49` - Initial FraudDetectionTopology with basic filter
- `i1l9j50` - Add branching logic for high-risk vs low-risk
- `j2m0k61` - Implement fraud detection rules (amount, region, merchant checks)
- `k3n1l72` - Add TopologyTestDriver tests with test data
- `l4o2m83` - Integration test with local broker

**Notes**:
- KStream = unbounded stream of events
- KTable = changelog stream (latest value per key)
- Branching returns Map<String, KStream> in new API
- TopologyTestDriver doesn't need running broker (huge win for CI!)
- Fraud rules I implemented:
  - Amount > $10,000 → high-risk
  - Region = "BLOCKED_COUNTRY" → high-risk
  - Otherwise → low-risk

**Knowledge Check**:
- [x] Understand KStream vs KTable: "KStream = events, KTable = state (latest per key)"
- [x] Can explain stream topology: "DAG of processing nodes: source → processors → sinks"
- [x] Can write TopologyTestDriver tests: "Unit tests without broker, in-memory state stores"
- [x] Understand stateless vs stateful operations: "filter/map = stateless, aggregate/join = stateful"

---

### Block 4: Iron Badge ⚙️
**Topic**: Configuration & Git-Flow
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 1 hour

**What I Learned**:
- 5-layer config resolution: defaults → env-specific → env vars → sys props → external file
- Environment-specific configs prevent hardcoding credentials
- Git-Flow branching: feature → develop → release → main (with hotfix for emergencies)
- Never commit secrets to version control!

**Exercises Completed**:
- [x] Understand 5-layer config resolution
- [x] Create application-dev.properties (localhost:9092)
- [x] Create application-qa.properties (Confluent Cloud DEV cluster)
- [x] Create application-prod.properties (placeholders for secrets)
- [x] Test config loading for different environments
- [x] Understand feature/release/hotfix branching

**Challenges**:
- Initially confused about config precedence order
- Accidentally committed API key to dev config (caught it before push!)
- Unsure when to use feature vs hotfix branch

**Solutions Found**:
- Mnemonic: "Defaults → Env files → ENV vars → SYS props → EXternal" (DEESE)
- Added .env to .gitignore, moved secrets there
- Learned: feature = new work from develop, hotfix = urgent fix from main

**Code Commits**:
- `m5p3n94` - Add application-dev.properties with local config
- `n6q4o05` - Add application-qa.properties with QA cluster config
- `o7r5p16` - Add application-prod.properties with ${PLACEHOLDER} for secrets
- `p8s6q27` - Add ConfigLoader tests for all environments
- `q9t7r38` - Document config resolution in README

**Notes**:
- Precedence (highest wins): External > SysProps > EnvVars > EnvFile > Defaults
- Use ${KAFKA_BOOTSTRAP_SERVERS} placeholders in prod configs
- Store secrets in K8s Secrets or Vault, NOT in git
- Git-Flow:
  - feature/* → develop (new features)
  - develop → release/* → main (releases)
  - main → hotfix/* → main (emergency fixes)

**Knowledge Check**:
- [x] Can explain config precedence order: "Defaults < EnvFile < EnvVar < SysProp < External"
- [x] Understand environment-specific overrides: "Same keys, different values per env"
- [x] Can explain Git-Flow branching strategy: "feature/develop/release/main/hotfix"
- [x] Know when to use feature vs hotfix branches: "feature=new work, hotfix=urgent prod fix"

---

### Block 5: Steel Badge 🛡️
**Topic**: Docker, Kubernetes & GitOps Deployment
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 2 hours

**What I Learned**:
- Multi-stage Docker builds reduce image size (build stage + runtime stage)
- PCI-DSS hardening: non-root user, minimal base image, no shell
- Kubernetes Deployments manage ReplicaSets which manage Pods
- Kustomize overlays allow environment-specific configs without duplication
- GitOps: git is source of truth, changes via PR

**Exercises Completed**:
- [x] Build Docker image with multi-stage Dockerfile
- [x] Understand PCI-DSS hardening (non-root user, minimal base)
- [x] Create kind cluster
- [x] Deploy to Kubernetes
- [x] Use Kustomize overlays for dev/qa/prod
- [x] Understand GitOps workflow

**Challenges**:
- Docker image was 800MB initially (included Maven cache)
- kind cluster creation failed first time (Docker memory limit)
- Kustomize patch syntax was confusing
- Pods were crashlooping due to missing ConfigMap

**Solutions Found**:
- Multi-stage build: build with maven:3.9-jdk-17, run with eclipse-temurin:17-jre → 200MB
- Increased Docker memory to 4GB in Docker Desktop settings
- Used strategic merge patches for Kustomize (easier than JSON patches)
- Created ConfigMap before deploying apps (`kubectl apply -k k8s/base/`)

**Code Commits**:
- `r0u8s49` - Create multi-stage Dockerfile for producer-consumer-app
- `s1v9t50` - Add PCI-DSS hardening: non-root user (appuser:1000)
- `t2w0u61` - Create kind cluster config with 3 nodes
- `u3x1v72` - Add Kubernetes base manifests (namespace, deployment, service)
- `v4y2w83` - Add Kustomize overlays for dev/qa/prod
- `w5z3x94` - Deploy to kind and verify pods running

**Notes**:
- Multi-stage Dockerfile pattern:
  ```dockerfile
  FROM maven:3.9-jdk-17 AS build
  COPY . .
  RUN mvn clean package -DskipTests

  FROM eclipse-temurin:17-jre
  COPY --from=build target/*.jar app.jar
  USER appuser
  ENTRYPOINT ["java", "-jar", "app.jar"]
  ```
- Kustomize overlay structure: base/ + overlays/{dev,qa,prod}/
- kind loads local images: `kind load docker-image <image>:<tag> --name <cluster>`
- GitOps flow: code change → PR → review → merge → auto-deploy

**Knowledge Check**:
- [x] Understand multi-stage Docker builds: "Build stage (large) + runtime stage (small)"
- [x] Can explain PCI-DSS container hardening: "Non-root, minimal base, no shell, health checks"
- [x] Understand Kubernetes deployments and services: "Deployment → ReplicaSet → Pods; Service → load balance to Pods"
- [x] Can explain Kustomize overlays: "Base + env-specific patches, no duplication"
- [x] Understand GitOps deployment flow: "Git = source of truth, PR = deploy trigger"

---

### Block 6: Diamond Badge 💎
**Topic**: Troubleshooting & Diagnostics
**Status**: ✅ Complete
**Date**: 2026-02-03
**Time Spent**: 1.5 hours

**What I Learned**:
- Connectivity issues: check bootstrap servers, network, SSL/SASL config
- Consumer lag = produced messages - consumed messages (per partition)
- Schema compatibility: BACKWARD (remove fields), FORWARD (add fields), FULL (both)
- JMX metrics expose internal Kafka metrics for monitoring
- kubectl logs and describe are your best friends for K8s debugging

**Exercises Completed**:
- [x] Diagnose broker connectivity issues
- [x] Check consumer lag with CLI tools
- [x] Debug schema compatibility issues
- [x] Use JMX metrics for monitoring
- [x] Run full diagnostics script

**Challenges**:
- Consumer lag was increasing - app wasn't crashing but not processing
- Schema compatibility error when I removed a required field
- JMX metrics overwhelming - didn't know which to monitor
- Pod was running but not responding to health checks

**Solutions Found**:
- Found infinite loop in consumer code (oops!) - fixed business logic
- Changed schema compatibility to BACKWARD, re-added field as optional
- Trainer recommended key metrics: fetch-rate, commit-latency, lag
- Health check was hitting wrong port (8080 vs 8081) - fixed in deployment

**Code Commits**:
- `x6a4y05` - Fix infinite loop in consumer processing logic
- `y7b5z16` - Update schema with optional field for backward compatibility
- `z8c6a27` - Add JMX metrics export to producer/consumer
- `a9d7b38` - Fix Kubernetes health check port configuration
- `b0e8c49` - Run diagnostics script and fix issues

**Notes**:
- Connectivity checklist:
  - ✅ Bootstrap servers correct?
  - ✅ Network allows connection?
  - ✅ SSL/SASL configured if required?
  - ✅ API key valid (Confluent Cloud)?
- Consumer lag tools:
  - `kafka-consumer-groups --describe --group <group>`
  - `confluent kafka consumer group lag describe <group>`
- Schema compatibility:
  - BACKWARD: consumers with new schema can read old data
  - FORWARD: consumers with old schema can read new data
  - FULL: both directions
- Key JMX metrics:
  - Producer: `record-send-rate`, `request-latency-avg`
  - Consumer: `records-consumed-rate`, `fetch-latency-avg`, `records-lag-max`

**Knowledge Check**:
- [x] Can diagnose connectivity issues: "Check servers, network, auth, SSL"
- [x] Understand consumer lag and how to fix it: "Lag = backlog; fix = scale consumers, optimize processing"
- [x] Can debug schema compatibility problems: "Understand BACKWARD/FORWARD/FULL, use optional fields"
- [x] Know how to access and interpret JMX metrics: "JMX port 9999, monitor send-rate, lag, latency"

---

### Level 101 Validation

**Final Validation**:
```bash
./scripts/workshop-check.sh final

✅ Block 1: Bronze Badge - PASS
✅ Block 2: Silver Badge - PASS
✅ Block 3: Gold Badge - PASS
✅ Block 4: Iron Badge - PASS
✅ Block 5: Steel Badge - PASS
✅ Block 6: Diamond Badge - PASS

🎉 Level 101 Complete! Master Badge Earned!
```

**Pull Request**:
- PR #: 42
- Status: ✅ Approved
- Reviewer: Alice Smith (trainer)
- Approval Date: 2026-02-03

**Trainer Feedback**:
- "Excellent work on the fraud detection topology! Clean code."
- "Good catch on the infinite loop in Block 6 - debugging skills strong."
- "Commit messages are very clear and descriptive."
- "Minor: Could add more edge case tests for card masking."
- "Overall: Ready for Level 201!"

**Master Badge Earned**: ✅ Yes (Date: 2026-02-03 17:00)

---

## 🔧 Level 201: Tool Mastery

**Overall Status**: ✅ Complete
**Tool Master Badge**: ✅ Earned (2026-02-04)

### Block 7: Smith Badge 🔨
**Topic**: Build Automation (Make, Maven)
**Status**: ✅ Complete
**Date**: 2026-02-04
**Time Spent**: 0.5 hours

**What I Learned**:
- Makefile provides single interface for entire project lifecycle
- Phony targets (build, test, clean) don't correspond to files
- Maven multi-module builds share parent POM for dependency management
- `make help` is essential for discoverability

**Exercises Completed**:
- [x] Understand Makefile structure
- [x] Use `make build`, `make test`, `make ci`
- [x] Understand Maven multi-module builds
- [x] Create custom Make targets

**Notes**:
- Created custom target: `make quick-test` (runs only unit tests, not integration)
- Maven reactor builds modules in dependency order automatically

---

### Block 8: Knight Badge ⚔️
**Topic**: Local Kubernetes (kind, Helm)
**Status**: ✅ Complete
**Date**: 2026-02-04
**Time Spent**: 1 hour

**What I Learned**:
- kind creates K8s clusters using Docker containers as nodes
- `kind load docker-image` avoids pushing to registry
- Helm charts = K8s YAML + templating + versioning
- Helm values files enable env-specific deployments

**Exercises Completed**:
- [x] Create kind cluster with 3 nodes (1 control-plane, 2 workers)
- [x] Load Docker images into kind
- [x] Deploy with Helm charts
- [x] Manage local K8s resources with kubectl

**Notes**:
- kind cluster creation takes ~30 seconds
- Loaded images persist in kind nodes (don't need to reload each time)

---

### Block 9: Inspector Badge 🔍
**Topic**: Load Testing & Traffic Management
**Status**: ✅ Complete
**Date**: 2026-02-04
**Time Spent**: 1 hour

**What I Learned**:
- k6 uses JavaScript for load test scripts
- VUs (virtual users) simulate concurrent load
- Thresholds define pass/fail criteria (error rate < 1%, p95 latency < 500ms)
- Stages allow ramping load up/down

**Exercises Completed**:
- [x] Write k6 load test scripts for payment API
- [x] Run load tests against local environment
- [x] Analyze performance metrics (throughput, latency, errors)
- [x] Understand shadow traffic testing concepts

**Notes**:
- Baseline performance: 1000 req/sec @ p95=120ms, 0.1% error rate
- Identified bottleneck: database connection pool (increased from 10 to 50)

---

### Block 10: Messenger Badge 📢
**Topic**: CLI Tools Mastery (Confluent CLI, kcat)
**Status**: ✅ Complete
**Date**: 2026-02-04
**Time Spent**: 1.5 hours

**What I Learned**:
- Confluent CLI can manage entire cloud environment via scripts
- kcat format strings are incredibly powerful for custom output
- kafka-consumer-groups can reset offsets (dangerous in prod!)
- kafka-producer-perf-test helps establish baseline throughput

**Exercises Completed**:
- [x] Master kcat commands (produce, consume, metadata)
- [x] Use Confluent CLI for cluster management
- [x] Use Kafka CLI tools (kafka-topics, kafka-consumer-groups)
- [x] Automate operations with CLI scripts

**Notes**:
- Created script to rotate API keys automatically with Confluent CLI
- kcat JSON output (`-J`) is perfect for piping to jq

---

### Level 201 Validation

**Pull Request**:
- PR #: 45
- Status: ✅ Approved
- Reviewer: Alice Smith

**Tool Master Badge Earned**: ✅ Yes (Date: 2026-02-04)

---

## 🏗️ Level 301: Engineering Excellence

**Overall Status**: 🔄 In Progress (3/5 blocks complete)
**Workshop Master Badge**: ⬜ Not Earned

### Block 11: Pipeline Badge 🔄
**Topic**: CI/CD Pipeline Engineering
**Status**: ✅ Complete
**Date**: 2026-02-05
**Time Spent**: 2 hours

**What I Learned**:
- GitHub Actions uses YAML workflows with jobs and steps
- Act lets you test workflows locally before pushing
- GitOps: deployments triggered by merged PRs
- Trivy scans Docker images for vulnerabilities (CVE database)

**Exercises Completed**:
- [x] Understand GitHub Actions workflows (.github/workflows/ci.yaml)
- [x] Test CI pipeline locally with Act
- [x] Implement GitOps deployment flow
- [x] Add security scanning with Trivy

**Notes**:
- Act saved me 3 rounds of "fix CI" commits - tested locally first!
- Trivy found 2 HIGH vulnerabilities in base image - upgraded to patched version

---

### Block 12: Strategist Badge 🎖️
**Topic**: Kubernetes Deployment Strategy
**Status**: ✅ Complete
**Date**: 2026-02-05
**Time Spent**: 1.5 hours

**What I Learned**:
- Resource requests = guaranteed resources, limits = max allowed
- Rolling updates = zero downtime deployments
- Health checks (liveness + readiness) prevent traffic to unhealthy pods
- NetworkPolicy restricts pod-to-pod communication (PCI-DSS requirement)

**Exercises Completed**:
- [x] Deploy to dev/qa/prod with Kustomize
- [x] Understand resource limits and requests
- [x] Implement rolling updates (maxSurge, maxUnavailable)
- [x] Configure health checks and probes

**Notes**:
- Set requests low enough for dev, high enough for prod
- readinessProbe: prevent traffic to unready pod
- livenessProbe: restart if pod is unhealthy

---

### Block 13: Load Tester Badge 📊
**Topic**: Load Testing & Traffic Management
**Status**: ✅ Complete
**Date**: 2026-02-05
**Time Spent**: 2 hours

**What I Learned**:
- Comprehensive load tests should cover: normal load, peak load, stress test
- SLA validation: p95 latency < 500ms, error rate < 0.1%, throughput > 1000 req/s
- Shadow traffic allows testing new code with prod traffic patterns
- k6 can output to InfluxDB for historical analysis

**Exercises Completed**:
- [x] Run comprehensive load tests (normal, peak, stress)
- [x] Analyze performance under load
- [x] Implement shadow traffic testing strategy
- [x] Validate SLA compliance

**Notes**:
- Stress test revealed memory leak at 5000 req/s sustained load
- Fixed by properly closing Kafka producer instances

---

### Block 14: Commander Badge 👨‍✈️
**Topic**: Confluent Cloud Automation
**Status**: 🔄 In Progress
**Date**: 2026-02-05 (ongoing)
**Time Spent**: 1 hour so far

**What I Learned** (so far):
- Confluent CLI can provision entire environments via scripts
- API keys should be rotated every 90 days (security best practice)
- Service accounts better than user accounts for apps

**Notes**:
- Working on automation script for environment provisioning
- Planning to document common operational runbooks

---

### Block 15: General Badge ⭐
**Topic**: End-to-End Release Simulation
**Status**: ⬜ Not Started

---

## 🎓 Final Reflection

### Overall Workshop Experience (So Far)

**Total Time Spent**: ~18 hours across 3 days (Level 101-201, partial 301)

**Biggest Learnings**:
1. Kafka Streams is WAY more powerful than I thought - love the testing story
2. Docker multi-stage builds drastically reduced image size
3. Kustomize overlays are elegant for managing multiple environments

**Most Challenging Topics**:
1. Kafka Streams topology design - had to think differently about data flow
2. Schema compatibility and evolution - easy to break consumers
3. Kubernetes resource limits - hard to predict right values

**Most Interesting Topics**:
1. Fraud detection with Kafka Streams (real-world use case!)
2. GitOps deployment flow (want to implement this at work)
3. TopologyTestDriver (testing without a broker is game-changing)

**How I'll Apply This Knowledge**:
- Propose Kafka Streams for our fraud detection system
- Set up GitOps deployment pipeline for our microservices
- Evangelize TopologyTestDriver for better testing practices

### Skills Gained

**Before Workshop** → **After Workshop**:
- Kafka Knowledge: Beginner → Advanced
- Stream Processing: Beginner → Advanced
- Kubernetes: Beginner → Intermediate
- CI/CD: Intermediate → Advanced
- Performance Tuning: Beginner → Intermediate

### Next Steps

**Immediate (next 1-2 weeks)**:
- [ ] Complete Level 301 (Blocks 14-15)
- [ ] Write internal wiki page sharing workshop learnings
- [ ] Present Kafka Streams to team as option for fraud detection

**Short-term (next 1-3 months)**:
- [ ] Implement MVP of fraud detection with Kafka Streams
- [ ] Set up GitOps pipeline for 2 microservices (pilot)
- [ ] Potentially take Level 401 if fraud detection project goes well

**Long-term (3-12 months)**:
- [ ] Lead migration of 5+ microservices to Kafka-based architecture
- [ ] Become team's Kafka subject matter expert
- [ ] Consider Confluent Certified Developer certification

### Feedback for Trainer

**What worked well**:
- Hands-on exercises were perfectly paced - not too easy, not too hard
- Real-world PCI-DSS scenario made it relevant
- Trainer (Alice) was very responsive to questions

**What could be improved**:
- Level 201 felt a bit rushed (could be a full day)
- Would love more troubleshooting scenarios in Level 101 Block 6
- Helm charts section was light - could go deeper

**Additional topics I'd like to see**:
- Kafka Connect deep dive
- ksqlDB vs Kafka Streams (when to use which)
- Multi-region Kafka deployments

**Overall Rating**: ⭐⭐⭐⭐⭐ (5/5 stars)

---

**Version**: 1.0
**Last Updated**: 2026-02-05
