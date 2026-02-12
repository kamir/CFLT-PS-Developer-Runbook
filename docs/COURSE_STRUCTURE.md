# Confluent Developer Runbook - Course Structure

## 🎯 Overview

This course is a **progressive certification program** for Confluent Cloud Java developers. It follows a **4-tier mastery model** with hands-on workshops, real-world scenarios, and automated validation.

**Scenario**: Building a PCI-DSS compliant payment processing pipeline on Confluent Cloud.

---

## 📊 Level Structure: 101 → 201 → 301 → 401

### **Level 101: Foundations** 🥉
**Duration**: 1 day (6 hours net, 8 hours with breaks)
**Target Audience**: Developers new to Kafka/Confluent Cloud
**Certification**: Master Badge (requires all 6 badges)

**What You'll Learn:**
- **Kafka Core Concepts**: Topics, producers, consumers, partitions, offsets
- **Schema Management**: Avro schemas with Schema Registry
- **Stream Processing**: Kafka Streams topology, KStream, KTable
- **Configuration Management**: Multi-environment config resolution (dev/qa/prod)
- **Containerization**: Docker basics, multi-stage builds
- **Kubernetes Deployment**: Basic K8s concepts, deployments, services
- **Troubleshooting**: Connectivity issues, consumer lag, schema compatibility

**Developer Flow Alignment:**
```
Learn to Read → Learn to Write → Learn to Process → Learn to Deploy → Learn to Debug
   Block 1-2        Block 2-3          Block 3           Block 4-5          Block 6
```

**Badges**:
1. 🥉 **Bronze Badge**: Local Dev Environment & First Messages
2. 🥈 **Silver Badge**: Producer/Consumer Deep Dive & PCI-DSS Compliance
3. 🥇 **Gold Badge**: Kafka Streams Topology & Fraud Detection
4. ⚙️ **Iron Badge**: Configuration & Git-Flow
5. 🛡️ **Steel Badge**: Docker, Kubernetes & GitOps Deployment
6. 💎 **Diamond Badge**: Troubleshooting & Diagnostics

**Prerequisites**:
- Java 17+ installed
- Basic Git knowledge
- Docker Desktop or Podman
- Terminal/shell familiarity
- GitHub account

**Key Deliverables**:
- Working producer-consumer application
- Kafka Streams fraud detection pipeline
- Docker containerized applications
- Kubernetes deployments (dev environment)

---

### **Level 201: Tool Mastery** 🔧
**Duration**: 0.5 day (4 hours)
**Target Audience**: Developers with Level 101 or equivalent Kafka experience
**Certification**: Tool Master Badge (requires all 4 badges)

**What You'll Learn:**
- **Build Automation**: Make, Maven multi-module builds
- **Local Kubernetes**: kind clusters, Helm charts
- **Load Testing**: k6 scripting, shadow traffic testing
- **CLI Tools**: Confluent CLI, Kafka CLI tools, kcat mastery

**Developer Flow Alignment:**
```
Automate Build → Test Locally → Validate Performance → Operate Clusters
   Block 7           Block 8          Block 9             Block 10
```

**Badges**:
7. 🔨 **Smith Badge**: Build Automation (Make, Maven)
8. ⚔️ **Knight Badge**: Local Kubernetes (kind, Helm)
9. 🔍 **Inspector Badge**: Load Testing & Traffic Management
10. 📢 **Messenger Badge**: Mastery of CLI Tools

**Prerequisites**:
- Level 101 certification OR
- 3+ months Kafka experience
- Familiarity with Linux command line

**Key Deliverables**:
- Makefile-based build pipeline
- Local kind cluster with deployed apps
- k6 load test scripts
- CLI automation scripts

---

### **Level 301: Engineering Excellence** 🏗️
**Duration**: 1 day (6-7 hours)
**Target Audience**: Developers preparing for production deployments
**Certification**: Workshop Master Badge (requires all 5 badges)

**What You'll Learn:**
- **CI/CD Pipeline Engineering**: GitHub Actions, Act local testing, GitOps
- **Kubernetes Strategy**: Kustomize overlays, environment promotion
- **Performance Testing**: Comprehensive load testing, SLA validation
- **Operational Runbooks**: Incident response, capacity planning
- **End-to-End Workflows**: Full release simulation (dev → qa → prod)

**Developer Flow Alignment:**
```
Automate Pipeline → Multi-Env Deploy → Load Test → Operate → Full Release
     Block 11           Block 12        Block 13      Block 14    Block 15
```

**Badges**:
11. 🔄 **Pipeline Badge**: CI/CD Pipeline Engineering
12. 🎖️ **Strategist Badge**: Kubernetes Deployment Strategy
13. 📊 **Load Tester Badge**: Load Testing & Traffic Management
14. 👨‍✈️ **Commander Badge**: Confluent Cloud Automation
15. ⭐ **General Badge**: End-to-End Release Simulation

**Prerequisites**:
- Level 201 certification OR
- 6+ months production Kafka experience
- CI/CD pipeline experience (Jenkins/GitLab/GitHub Actions)

**Key Deliverables**:
- Complete CI/CD pipeline (GitHub Actions)
- Multi-environment Kustomize overlays
- Production-ready load tests
- Operational runbooks
- Full release workflow documentation

---

### **Level 401: Performance Optimization** ⚡
**Duration**: 1 day (6-7 hours)
**Target Audience**: Senior developers, architects, performance engineers
**Certification**: Grand Master Badge (requires all 4 badges)

**What You'll Learn:**
- **Producer/Consumer Tuning**: Batch size, linger.ms, compression, throughput optimization
- **Kafka Streams Optimization**: RocksDB tuning, state store configuration, processing guarantees
- **Kubernetes Resource Tuning**: JVM heap sizing, GC tuning, CPU/memory optimization
- **Production Load Testing**: Stress testing, capacity planning, SLA validation

**Developer Flow Alignment:**
```
Measure Baseline → Tune Clients → Tune Streams → Tune Infrastructure → Validate at Scale
     Block 16         Block 17       Block 18           Block 18              Block 19
```

**Badges**:
16. 🎚️ **Tuner Badge**: Producer & Consumer Throughput Optimization
17. ⚙️ **Engineer Badge**: Kafka Streams & RocksDB Optimization
18. 🏛️ **Architect Badge**: K8s Resource Tuning & JVM Optimization
19. 🎖️ **Field Marshal Badge**: Production Load Testing & Capacity Planning

**Prerequisites**:
- Level 301 certification OR
- 1+ year production Kafka experience
- Performance tuning experience
- Understanding of JVM internals

**Key Deliverables**:
- Performance tuning playbook
- Optimized producer/consumer configurations
- RocksDB state store configurations
- JVM tuning parameters
- Load test results with SLA validation

---

## 🎓 Certification Paths

### **Path 1: Full Stack Developer (All Levels)**
```
101 → 201 → 301 → 401 = Grand Master
```
**Timeline**: 3.5-4 days intensive OR 2-3 weeks part-time
**Target**: Developers building production-grade Kafka applications

### **Path 2: Application Developer (101 + 201)**
```
101 → 201 = Tool Master
```
**Timeline**: 1.5 days
**Target**: Developers building Kafka applications (not deploying)

### **Path 3: Platform Engineer (101 + 301)**
```
101 → 301 = Workshop Master
```
**Timeline**: 2 days
**Target**: DevOps/SRE focusing on deployment and operations

### **Path 4: Performance Specialist (101 + 401)**
```
101 → 401 = Performance Expert
```
**Timeline**: 2 days
**Target**: Architects and performance engineers

---

## 📈 Learning Progression

### **Cognitive Levels** (Bloom's Taxonomy)

| Level | Focus | Bloom's Level | Skills |
|-------|-------|---------------|--------|
| **101** | **Remember & Understand** | L1-L2 | Recall Kafka concepts, understand producer/consumer patterns |
| **201** | **Apply** | L3 | Use tools to build, test, deploy applications |
| **301** | **Analyze & Evaluate** | L4-L5 | Design CI/CD pipelines, evaluate deployment strategies |
| **401** | **Create & Optimize** | L6 | Optimize performance, create tuning strategies |

### **Skill Maturity Model**

| Level | Developer Capability | Time to Proficiency |
|-------|---------------------|---------------------|
| **101** | Can build basic Kafka applications with guidance | 2-4 weeks practice |
| **201** | Can independently build and test Kafka apps | 1-2 months practice |
| **301** | Can deploy and operate production Kafka systems | 3-6 months practice |
| **401** | Can optimize and troubleshoot complex Kafka systems | 6-12 months practice |

---

## 🔄 Developer Flow Validation

### **Does the structure fit the developer journey?**

**✅ YES** - The structure follows a natural progression:

```
101: Learn the Fundamentals
  ↓
  "I can write Kafka code"
  ↓
201: Master the Tools
  ↓
  "I can build and test efficiently"
  ↓
301: Production Readiness
  ↓
  "I can deploy to production safely"
  ↓
401: Excellence & Optimization
  ↓
  "I can optimize for performance and cost"
```

### **Alignment with Real-World Developer Tasks**

| Real-World Task | Course Coverage | Level |
|-----------------|-----------------|-------|
| Add new Kafka consumer | Producer/Consumer patterns | 101 (Block 2) |
| Implement stream processing | Kafka Streams topology | 101 (Block 3) |
| Configure for different environments | Config management | 101 (Block 4) |
| Containerize application | Docker multi-stage builds | 101 (Block 5) |
| Deploy to Kubernetes | K8s deployments | 101 (Block 5) |
| Set up CI/CD pipeline | GitHub Actions, GitOps | 301 (Block 11) |
| Troubleshoot consumer lag | Diagnostics, JMX metrics | 101 (Block 6), 401 |
| Optimize throughput | Producer/consumer tuning | 401 (Block 16) |
| Tune stream processing | RocksDB optimization | 401 (Block 17) |
| Scale for production load | Capacity planning | 401 (Block 19) |

---

## 🎯 Success Criteria

### **Level 101 Completion**
- [ ] Can explain Kafka core concepts (topics, partitions, offsets)
- [ ] Can write producer and consumer code with error handling
- [ ] Can build Kafka Streams topology with branching logic
- [ ] Can configure applications for dev/qa/prod environments
- [ ] Can containerize and deploy to Kubernetes
- [ ] Can diagnose basic connectivity and lag issues
- [ ] **Badge**: Master Badge (all 6 Level 101 badges earned)

### **Level 201 Completion**
- [ ] Can automate builds with Make and Maven
- [ ] Can create local Kubernetes clusters with kind
- [ ] Can write k6 load tests
- [ ] Can operate Confluent Cloud with CLI tools
- [ ] **Badge**: Tool Master Badge (all 4 Level 201 badges earned)

### **Level 301 Completion**
- [ ] Can design and implement CI/CD pipelines
- [ ] Can manage multi-environment deployments with Kustomize
- [ ] Can perform comprehensive load testing
- [ ] Can write operational runbooks
- [ ] Can execute full release workflows
- [ ] **Badge**: Workshop Master Badge (all 5 Level 301 badges earned)

### **Level 401 Completion**
- [ ] Can optimize producer/consumer for throughput
- [ ] Can tune Kafka Streams and RocksDB
- [ ] Can optimize JVM and Kubernetes resources
- [ ] Can perform production-grade capacity planning
- [ ] **Badge**: Grand Master Badge (all 4 Level 401 badges earned)

---

## 📚 Additional Resources

- **RUNBOOK.md**: Complete developer reference for all environments
- **docs/workshop/LERNPFAD.md**: Detailed learning path with knowledge checks
- **docs/workshop/HANDS-ON-LAB.md**: Step-by-step lab guide for Level 101
- **docs/workshop/TOOLS.md**: Comprehensive tool reference
- **scripts/workshop-check.sh**: Automated validation for badge completion

---

## 🆘 Support

- **During Workshop**: Ask your trainer
- **After Workshop**: Check RUNBOOK.md for common issues
- **Community**: Confluent Community Slack

---

**Version**: 1.0
**Last Updated**: 2026-02-11
