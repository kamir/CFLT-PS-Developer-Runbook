# 🔧 Tools Warm-Up Guide - Pre-Workshop Learning

> **Recommended Preparation Time**: 4-8 hours over 1-2 weeks before the workshop
>
> This guide introduces all tools used in the Confluent Developer Workshop with curated learning resources from official vendors, universities, and industry experts.

---

## 📋 Table of Contents

1. [Core Development Tools](#1-core-development-tools)
2. [Kafka & Confluent Tools](#2-kafka--confluent-tools)
3. [Containerization & Orchestration](#3-containerization--orchestration)
4. [Build & Automation](#4-build--automation)
5. [Testing & Validation](#5-testing--validation)
6. [Quick Reference Card](#6-quick-reference-card)

---

## 🎯 Learning Path Overview

### **Before the Workshop** (Essential - 4 hours minimum)

**Week 1-2 Before Workshop**:
- ✅ Java & Maven basics (1 hour)
- ✅ Git & GitHub fundamentals (1 hour)
- ✅ Docker basics (1.5 hours)
- ✅ Kafka concepts (30 minutes reading)

### **Optional but Recommended** (4 hours additional)

- 🔷 Kubernetes basics (2 hours)
- 🔷 Make basics (30 minutes)
- 🔷 Confluent Cloud overview (30 minutes)
- 🔷 kcat quick start (30 minutes)
- 🔷 k6 introduction (30 minutes)

### **Advanced Pre-Study** (for experienced developers)

- 🔸 Kafka Streams concepts (1 hour)
- 🔸 GitHub Actions (30 minutes)
- 🔸 Helm basics (30 minutes)

---

## 1. Core Development Tools

### 1.1 Java (JDK 17+)

**Why**: All workshop applications are built with Java 17.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Oracle Java 17 Documentation](https://docs.oracle.com/en/java/javase/17/) - Official Oracle JDK 17 docs
- [Eclipse Temurin (AdoptOpenJDK)](https://adoptium.net/) - Recommended open-source JDK distribution

**University Courses**:
- [MIT 6.092: Introduction to Java](https://ocw.mit.edu/courses/6-092-introduction-to-programming-in-java-january-iap-2010/) - MIT OpenCourseWare
- [Princeton COS 126: Computer Science](https://www.cs.princeton.edu/courses/archive/spring21/cos126/) - Uses Java

**Expert Tutorials**:
- [Java Tutorial by Oracle](https://docs.oracle.com/javase/tutorial/) - Comprehensive official tutorial
- [Baeldung Java Tutorials](https://www.baeldung.com/java-tutorial) - Practical, modern Java examples
- [Java Code Geeks](https://www.javacodegeeks.com/) - Java best practices and patterns

**Interactive Learning**:
- [Codecademy: Learn Java](https://www.codecademy.com/learn/learn-java) - Interactive exercises
- [JetBrains Academy: Java](https://www.jetbrains.com/academy/) - Project-based learning

**Video Courses**:
- [Java Programming Masterclass (Udemy)](https://www.udemy.com/course/java-the-complete-java-developer-course/) - Tim Buchalka
- [Java Full Course (YouTube)](https://www.youtube.com/watch?v=xk4_1vDrzzo) - Free comprehensive course

**Time Required**: 1 hour to review Java 17 features if you know Java 8/11

**What to Focus On**:
- ✅ Records (modern data classes)
- ✅ Streams API
- ✅ CompletableFuture (async programming)
- ✅ var keyword (type inference)

---

### 1.2 Maven

**Why**: Build tool for compiling, testing, and packaging Java applications.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Apache Maven Official Guide](https://maven.apache.org/guides/index.html) - Complete reference
- [Maven in 5 Minutes](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html) - Quick start

**Expert Tutorials**:
- [Baeldung Maven Guides](https://www.baeldung.com/maven) - Comprehensive Maven tutorials
- [Maven by Example (Sonatype)](https://books.sonatype.com/mvnex-book/reference/index.html) - Free book

**Video Courses**:
- [Maven Tutorial for Beginners (YouTube)](https://www.youtube.com/watch?v=Xatr8AZLOsE) - In28Minutes
- [Apache Maven Beginner to Guru (Udemy)](https://www.udemy.com/course/apache-maven-beginner-to-guru/) - John Thompson

**Time Required**: 30 minutes for basics

**What to Focus On**:
- ✅ Understanding `pom.xml` structure
- ✅ Maven lifecycle: `clean`, `compile`, `test`, `package`, `verify`
- ✅ Multi-module projects
- ✅ Dependencies and dependency management

**Quick Commands to Practice**:
```bash
mvn clean package          # Build the project
mvn test                   # Run tests
mvn dependency:tree        # Show dependency tree
mvn clean verify           # Full build with tests
```

---

### 1.3 Git & GitHub

**Why**: Version control for all workshop code and collaboration.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Git Official Documentation](https://git-scm.com/doc) - Complete reference
- [GitHub Docs](https://docs.github.com/en) - GitHub-specific features
- [Pro Git Book (Free)](https://git-scm.com/book/en/v2) - Comprehensive guide by Scott Chacon

**University Courses**:
- [MIT: The Missing Semester - Version Control](https://missing.csail.mit.edu/2020/version-control/) - Excellent fundamentals

**Interactive Learning**:
- [Learn Git Branching](https://learngitbranching.js.org/) - Visual, interactive tutorial
- [GitHub Skills](https://skills.github.com/) - Hands-on GitHub learning
- [GitKraken Learn](https://www.gitkraken.com/learn/git/tutorials) - Visual Git tutorials

**Expert Tutorials**:
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials) - Excellent guides from Bitbucket team
- [Git Immersion](https://gitimmersion.com/) - Hands-on lab tutorial
- [Oh Shit, Git!?!](https://ohshitgit.com/) - Common Git problems and solutions

**Video Courses**:
- [Git & GitHub Crash Course (YouTube)](https://www.youtube.com/watch?v=RGOj5yH7evk) - freeCodeCamp
- [Git and GitHub for Beginners (YouTube)](https://www.youtube.com/watch?v=tRZGeaHPoaw) - Kevin Stratvert

**Time Required**: 1 hour for Git basics, 30 minutes for GitHub

**What to Focus On**:
- ✅ Basic commands: `clone`, `add`, `commit`, `push`, `pull`
- ✅ Branching: `branch`, `checkout`, `merge`
- ✅ Pull Requests and code review
- ✅ SSH key setup for GitHub

**Workshop-Specific Git Flow**:
```bash
git checkout -b student/<your-username>
git add <files>
git commit -m "Block 2: Implement card masking"
git push origin student/<your-username>
gh pr create --base main --head student/<your-username>
```

---

## 2. Kafka & Confluent Tools

### 2.1 Apache Kafka Fundamentals

**Why**: Core technology for the entire workshop.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/) - Official reference
- [Kafka Introduction](https://kafka.apache.org/intro) - High-level overview
- [Confluent Documentation](https://docs.confluent.io/) - Comprehensive Confluent Platform docs

**Books (Industry Standard)**:
- [**Kafka: The Definitive Guide**](https://www.confluent.io/resources/kafka-the-definitive-guide/) - Neha Narkhede, Gwen Shapira, Todd Palino (FREE from Confluent)
- [**Designing Data-Intensive Applications**](https://dataintensive.net/) - Martin Kleppmann (Chapter on stream processing)
- [Event Streaming with Kafka](https://www.oreilly.com/library/view/event-streaming-with/9781484271698/) - Tomasz Lelek

**University Courses**:
- [UC Berkeley CS 262a: Advanced Topics in Computer Systems](https://people.eecs.berkeley.edu/~kubitron/courses/cs262a-F21/) - Covers distributed systems including Kafka
- [CMU 15-440: Distributed Systems](https://www.cs.cmu.edu/~dga/15-440/S14/) - Foundational concepts

**Confluent Official Learning**:
- [Confluent Developer](https://developer.confluent.io/) - Official learning portal
- [Kafka 101 Course (Confluent)](https://developer.confluent.io/learn-kafka/apache-kafka/events/) - Free interactive course
- [Kafka Streams 101 (Confluent)](https://developer.confluent.io/learn-kafka/kafka-streams/get-started/) - Stream processing basics
- [Confluent Fundamentals for Apache Kafka](https://training.confluent.io/learningpath/confluent-fundamentals-for-apache-kafka) - Official training

**Expert Blogs & Articles**:
- [Confluent Blog](https://www.confluent.io/blog/) - Latest Kafka insights
- [Jay Kreps' Blog](https://www.linkedin.com/in/jaykreps/) - Co-creator of Kafka
- [Martin Kleppmann's Blog](https://martin.kleppmann.com/) - Distributed systems expert
- [Kafka Internals by Jun Rao](https://www.confluent.io/blog/author/jun/) - Kafka co-creator

**Video Courses**:
- [Apache Kafka for Beginners (Udemy)](https://www.udemy.com/course/apache-kafka/) - Stephane Maarek
- [Kafka Streams for Data Processing (Udemy)](https://www.udemy.com/course/kafka-streams/) - Stephane Maarek
- [Kafka Tutorial (YouTube - Confluent)](https://www.youtube.com/c/Confluent) - Official channel

**Interactive Learning**:
- [Confluent Cloud Free Tier](https://www.confluent.io/confluent-cloud/tryfree/) - Hands-on with real Kafka cluster
- [Kafka Tutorials](https://kafka-tutorials.confluent.io/) - Step-by-step recipes

**Time Required**: 2-3 hours for fundamentals

**Key Concepts to Understand**:
- ✅ Topics, Partitions, Offsets
- ✅ Producers and Consumers
- ✅ Consumer Groups
- ✅ Replication and ISR (In-Sync Replicas)
- ✅ At-least-once vs. exactly-once semantics
- ✅ Schema Registry and Avro

---

### 2.2 Kafka Streams

**Why**: Used in Block 3 for fraud detection topology.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Kafka Streams Documentation](https://kafka.apache.org/documentation/streams/) - Official reference
- [Kafka Streams Developer Guide](https://docs.confluent.io/platform/current/streams/developer-guide/dsl-api.html) - Confluent version

**Books**:
- [**Kafka Streams in Action**](https://www.manning.com/books/kafka-streams-in-action) - William P. Bejeck Jr.
- [Mastering Kafka Streams and ksqlDB](https://www.oreilly.com/library/view/mastering-kafka-streams/9781492062486/) - Mitch Seymour

**Confluent Resources**:
- [Kafka Streams 101 (Confluent)](https://developer.confluent.io/learn-kafka/kafka-streams/get-started/) - Interactive course
- [Kafka Streams Examples](https://github.com/confluentinc/kafka-streams-examples) - Official examples repo

**Expert Tutorials**:
- [Confluent Kafka Streams Blog Series](https://www.confluent.io/blog/category/kafka-streams/) - Matthias J. Sax and team
- [Baeldung Kafka Streams](https://www.baeldung.com/java-kafka-streams) - Practical examples

**Video Courses**:
- [Kafka Streams for Data Processing (Udemy)](https://www.udemy.com/course/kafka-streams/) - Stephane Maarek
- [Kafka Streams (YouTube - Confluent)](https://www.youtube.com/watch?v=Z3JKCLG3VP4) - Tim Berglund

**Time Required**: 1 hour for basics (more covered in workshop)

**What to Focus On**:
- ✅ KStream vs KTable
- ✅ Stateless operations: `filter`, `map`, `flatMap`
- ✅ Stateful operations: `groupBy`, `aggregate`, `join`
- ✅ Branching and topology design
- ✅ TopologyTestDriver for testing

---

### 2.3 Confluent CLI

**Why**: Manage Confluent Cloud resources from the command line.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Confluent CLI Overview](https://docs.confluent.io/confluent-cli/current/overview.html) - Complete reference
- [Confluent CLI Command Reference](https://docs.confluent.io/confluent-cli/current/command-reference/index.html) - All commands

**Official Tutorials**:
- [Confluent CLI Quick Start](https://docs.confluent.io/confluent-cli/current/get-started.html) - Getting started guide
- [Confluent Cloud CLI Tutorial](https://docs.confluent.io/cloud/current/get-started/index.html) - Cloud-specific guide

**Video Tutorials**:
- [Confluent CLI Deep Dive (YouTube)](https://www.youtube.com/watch?v=mEPdmPAvYbI) - Official Confluent
- [Automating Confluent Cloud with CLI](https://www.youtube.com/watch?v=TqxWLCEDOQc) - Confluent

**Time Required**: 30 minutes

**Essential Commands to Practice**:
```bash
confluent login
confluent environment list
confluent kafka cluster list
confluent kafka topic list
confluent kafka topic produce <topic>
confluent kafka topic consume <topic>
```

---

### 2.4 kcat (formerly kafkacat)

**Why**: Fast, lightweight tool for Kafka message inspection.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [kcat GitHub Repository](https://github.com/edenhill/kcat) - Official repo with docs
- [kcat README](https://github.com/edenhill/kcat#readme) - Usage guide

**Expert Tutorials**:
- [Robin Moffatt's kcat Cheat Sheet](https://dev.to/confluentinc/kcat-the-swiss-army-knife-of-kafka-tools-3p12) - Comprehensive guide
- [Confluent: Using kcat](https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/kcat.html) - Official tutorial

**Video Tutorials**:
- [kcat Tutorial (YouTube)](https://www.youtube.com/watch?v=PvMeXFfJhzw) - Robin Moffatt

**Time Required**: 20 minutes

**Essential Commands to Practice**:
```bash
kcat -b localhost:9092 -L                    # List metadata
kcat -b localhost:9092 -t payments -C        # Consume
kcat -b localhost:9092 -t payments -P        # Produce
```

---

## 3. Containerization & Orchestration

### 3.1 Docker & Docker Compose

**Why**: Containerize applications and run local Kafka environments.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Docker Official Documentation](https://docs.docker.com/) - Complete reference
- [Docker Get Started Guide](https://docs.docker.com/get-started/) - Official tutorial
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Compose reference

**Books**:
- [**Docker Deep Dive**](https://www.amazon.com/Docker-Deep-Dive-Nigel-Poulton/dp/1521822808) - Nigel Poulton
- [Docker in Action](https://www.manning.com/books/docker-in-action-second-edition) - Jeff Nickoloff

**University Courses**:
- [MIT: The Missing Semester - Metaprogramming](https://missing.csail.mit.edu/2020/metaprogramming/) - Includes containers

**Interactive Learning**:
- [Play with Docker](https://labs.play-with-docker.com/) - Free online Docker playground
- [Docker Curriculum](https://docker-curriculum.com/) - Interactive tutorial
- [KodeKloud Docker Courses](https://kodekloud.com/courses/docker-for-the-absolute-beginner/) - Hands-on labs

**Expert Tutorials**:
- [Docker Tutorial for Beginners (YouTube)](https://www.youtube.com/watch?v=fqMOX6JJhGo) - freeCodeCamp (2+ hours)
- [Docker Mastery (Udemy)](https://www.udemy.com/course/docker-mastery/) - Bret Fisher
- [Docker Tutorials (DigitalOcean)](https://www.digitalocean.com/community/tags/docker) - Excellent written guides

**Confluent-Specific**:
- [Confluent Docker Images](https://docs.confluent.io/platform/current/installation/docker/image-reference.html) - Official images
- [cp-all-in-one Docker Compose](https://github.com/confluentinc/cp-all-in-one) - Confluent Platform examples

**Time Required**: 1.5 hours for Docker basics, 30 minutes for Compose

**What to Focus On**:
- ✅ Docker images vs containers
- ✅ Dockerfile: `FROM`, `COPY`, `RUN`, `CMD`, `ENTRYPOINT`
- ✅ Multi-stage builds (used in workshop)
- ✅ Docker Compose: services, networks, volumes
- ✅ `docker ps`, `docker logs`, `docker exec`

**Practice Exercise**:
```bash
# Run Kafka locally with Docker Compose
cd CFLT-PS-Developer-Runbook
docker compose -f docker/docker-compose.yml up -d
docker ps
docker logs broker
```

---

### 3.2 Kubernetes

**Why**: Deploy applications to production-like environments.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/) - Complete reference
- [Kubernetes Basics Tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/) - Interactive tutorial
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/) - Core concepts

**Books**:
- [**Kubernetes: Up and Running**](https://www.oreilly.com/library/view/kubernetes-up-and/9781492046523/) - Kelsey Hightower, Brendan Burns, Joe Beda
- [Kubernetes in Action](https://www.manning.com/books/kubernetes-in-action-second-edition) - Marko Lukša
- [The Kubernetes Book](https://www.amazon.com/Kubernetes-Book-Nigel-Poulton/dp/1521823634) - Nigel Poulton

**University Courses**:
- [Stanford CS 349D: Cloud Computing Technology](https://web.stanford.edu/class/cs349d/) - Includes Kubernetes
- [UC Berkeley CS 194: Cloud Computing and Big Data](https://www2.eecs.berkeley.edu/Courses/CS194-24/) - Container orchestration

**Interactive Learning**:
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) - Kelsey Hightower (deep dive)
- [Play with Kubernetes](https://labs.play-with-k8s.com/) - Free online K8s playground
- [KodeKloud Kubernetes Courses](https://kodekloud.com/courses/kubernetes-for-the-absolute-beginners-hands-on/) - Hands-on labs
- [Kubernetes Learning Path (Microsoft)](https://azure.microsoft.com/en-us/resources/kubernetes-learning-path/) - Comprehensive path

**Expert Tutorials**:
- [Kubernetes Tutorial for Beginners (YouTube)](https://www.youtube.com/watch?v=X48VuDVv0do) - TechWorld with Nana (4 hours)
- [Kubernetes Course (YouTube)](https://www.youtube.com/watch?v=d6WC5n9G_sM) - freeCodeCamp
- [Kubernetes Certified Admin (CKA) Course](https://www.udemy.com/course/certified-kubernetes-administrator-with-practice-tests/) - Mumshad Mannambeth

**CNCF Official Resources**:
- [CNCF Kubernetes Training](https://www.cncf.io/certification/training/) - Official training
- [Introduction to Kubernetes (edX)](https://www.edx.org/course/introduction-to-kubernetes) - Free CNCF course

**Time Required**: 2 hours for basics (more covered in workshop)

**What to Focus On**:
- ✅ Pods, Deployments, Services
- ✅ ConfigMaps and Secrets
- ✅ Namespaces
- ✅ Resource requests and limits
- ✅ Basic `kubectl` commands

**Essential kubectl Commands**:
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl apply -f deployment.yaml
kubectl get services
kubectl port-forward <pod-name> 8080:8080
```

---

### 3.3 kind (Kubernetes in Docker)

**Why**: Run local Kubernetes clusters for testing.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [kind Official Documentation](https://kind.sigs.k8s.io/) - Complete guide
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) - Getting started

**Tutorials**:
- [kind Tutorial (Kubernetes.io)](https://kubernetes.io/docs/tasks/tools/#kind) - Official K8s docs
- [Local Kubernetes Development with kind](https://piotrminkowski.com/2020/02/25/local-kubernetes-development-with-kind/) - Expert blog

**Video Tutorials**:
- [kind Tutorial (YouTube)](https://www.youtube.com/watch?v=m-IlbCgSzkc) - Just me and Opensource

**Time Required**: 20 minutes

**Quick Start**:
```bash
kind create cluster --name workshop
kubectl cluster-info --context kind-workshop
kind delete cluster --name workshop
```

---

### 3.4 Helm

**Why**: Package and deploy Kubernetes applications.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Helm Official Documentation](https://helm.sh/docs/) - Complete reference
- [Helm Get Started Guide](https://helm.sh/docs/intro/quickstart/) - Quick start

**Books**:
- [Learning Helm](https://www.oreilly.com/library/view/learning-helm/9781492083641/) - Matt Butcher, Matt Farina, Josh Dolitsky

**Tutorials**:
- [Helm Tutorial for Beginners (YouTube)](https://www.youtube.com/watch?v=-ykwb1d0DXU) - TechWorld with Nana
- [Helm Deep Dive (Pluralsight)](https://www.pluralsight.com/courses/kubernetes-packaging-applications-helm) - Philippe Collignon

**Interactive Learning**:
- [Helm Hub](https://artifacthub.io/) - Discover and browse Helm charts

**Time Required**: 30 minutes for basics

**What to Focus On**:
- ✅ Charts, templates, values
- ✅ `helm install`, `helm upgrade`, `helm rollback`
- ✅ Chart repositories

---

## 4. Build & Automation

### 4.1 GNU Make

**Why**: Unified command interface for all build, test, and deploy operations.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [GNU Make Manual](https://www.gnu.org/software/make/manual/) - Complete reference

**Books**:
- [Managing Projects with GNU Make](https://www.oreilly.com/library/view/managing-projects-with/0596006101/) - Robert Mecklenburg

**Tutorials**:
- [Make Tutorial (YouTube)](https://www.youtube.com/watch?v=_r7i5X0rXJk) - ProgrammingKnowledge
- [Makefile Tutorial (opensource.com)](https://opensource.com/article/18/8/what-how-makefile) - Excellent intro

**University Resources**:
- [MIT: The Missing Semester - Build Systems](https://missing.csail.mit.edu/2020/metaprogramming/) - Covers Make

**Time Required**: 30 minutes

**What to Focus On**:
- ✅ Targets and dependencies
- ✅ Variables
- ✅ Phony targets (`.PHONY`)
- ✅ Reading Makefiles

**Workshop Makefile Examples**:
```makefile
make help          # Show all targets
make build         # Build Java applications
make test          # Run tests
make docker-build  # Build Docker images
make local-up      # Start local environment
```

---

### 4.2 GitHub Actions

**Why**: CI/CD automation (covered in Level 301).

#### 📚 Essential Learning Resources

**Official Documentation**:
- [GitHub Actions Documentation](https://docs.github.com/en/actions) - Complete reference
- [GitHub Actions Quickstart](https://docs.github.com/en/actions/quickstart) - Getting started

**Interactive Learning**:
- [GitHub Skills: GitHub Actions](https://skills.github.com/) - Hands-on labs
- [GitHub Actions by Example](https://www.actionsbyexample.com/) - Practical examples

**Expert Tutorials**:
- [GitHub Actions Tutorial (YouTube)](https://www.youtube.com/watch?v=R8_veQiYBjI) - TechWorld with Nana
- [GitHub Actions for CI/CD (YouTube)](https://www.youtube.com/watch?v=mFFXuXjVgkU) - freeCodeCamp

**Time Required**: 30 minutes for overview (more in Level 301)

---

### 4.3 Act (Local GitHub Actions)

**Why**: Test GitHub Actions workflows locally.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [Act GitHub Repository](https://github.com/nektos/act) - Official docs
- [Act Website](https://nektosact.com/) - Usage guide

**Tutorials**:
- [Act Tutorial (YouTube)](https://www.youtube.com/watch?v=pby0k2bTzCY) - DevOps Journey

**Time Required**: 15 minutes

---

## 5. Testing & Validation

### 5.1 k6 (Load Testing)

**Why**: Performance and load testing for Kafka applications.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [k6 Official Documentation](https://k6.io/docs/) - Complete reference
- [k6 Getting Started](https://k6.io/docs/getting-started/running-k6/) - Quick start

**Interactive Learning**:
- [k6 Learn Portal](https://k6.io/docs/learn/) - Official learning path
- [Grafana k6 Learning](https://grafana.com/docs/k6/latest/) - Latest docs from Grafana

**Expert Tutorials**:
- [k6 Tutorial (YouTube)](https://www.youtube.com/watch?v=brasMBAezJY) - Let's Test
- [Load Testing with k6 (YouTube)](https://www.youtube.com/watch?v=r-Jte8Y8zag) - freeCodeCamp

**University Resources**:
- [Performance Testing Best Practices](https://cs.stanford.edu/people/widom/cs346/performance.html) - Stanford CS 346

**Time Required**: 30 minutes for basics

**What to Focus On**:
- ✅ Writing k6 scripts in JavaScript
- ✅ Virtual users (VUs) and stages
- ✅ Thresholds and checks
- ✅ Metrics: response time, error rate

**Sample k6 Script**:
```javascript
import http from 'k6/http';
import { check } from 'k6';

export default function () {
  const res = http.get('http://localhost:8080/api/payments');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
```

---

### 5.2 ngrok

**Why**: Expose local services for webhook testing.

#### 📚 Essential Learning Resources

**Official Documentation**:
- [ngrok Documentation](https://ngrok.com/docs) - Complete reference
- [ngrok Getting Started](https://ngrok.com/docs/getting-started/) - Quick start

**Tutorials**:
- [ngrok Tutorial (YouTube)](https://www.youtube.com/watch?v=fYz5gU6xRhM) - Traversy Media

**Time Required**: 15 minutes

---

## 6. Quick Reference Card

### Tool Installation Quick Reference

```bash
# Java
brew install openjdk@17              # macOS
sudo apt install openjdk-17-jdk      # Ubuntu

# Maven
brew install maven                   # macOS
sudo apt install maven               # Ubuntu

# Git
brew install git                     # macOS (usually pre-installed)
sudo apt install git                 # Ubuntu

# Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# Confluent CLI
brew install confluentinc/tap/cli    # macOS
curl -sL https://cnfl.io/cli | sh    # Linux

# kcat
brew install kcat                    # macOS
sudo apt install kafkacat            # Ubuntu (old name)

# kubectl
brew install kubectl                 # macOS
sudo snap install kubectl --classic  # Ubuntu

# kind
brew install kind                    # macOS
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && chmod +x ./kind  # Linux

# Helm
brew install helm                    # macOS
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash  # Linux

# k6
brew install k6                      # macOS
sudo apt install k6                  # Ubuntu (via GPG key)

# Act
brew install act                     # macOS
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash  # Linux

# ngrok
brew install ngrok                   # macOS
snap install ngrok                   # Ubuntu
```

---

### Learning Checklist

**Before Day 1 of Workshop** (Essential):
- [ ] Java 17 installed and working: `java -version`
- [ ] Maven installed: `mvn -version`
- [ ] Git configured with SSH key: `ssh -T git@github.com`
- [ ] Docker Desktop running: `docker ps`
- [ ] Read Kafka basics (30 min): Topics, Producers, Consumers
- [ ] Clone workshop repository and run environment check

**Recommended Pre-Study** (4 hours):
- [ ] Complete Docker tutorial (1.5 hours)
- [ ] Complete Kubernetes basics (2 hours)
- [ ] Read "Kafka: The Definitive Guide" Chapter 1-2 (30 minutes)

**Advanced Pre-Study** (Optional):
- [ ] Kafka Streams 101 course (Confluent)
- [ ] GitHub Actions overview
- [ ] kcat hands-on practice

---

### Recommended Reading Order

**Week 2 Before Workshop**:
1. **Day 1-2**: Java 17 features + Maven basics (1.5 hours)
2. **Day 3**: Git & GitHub (1 hour)
3. **Day 4-5**: Docker & Docker Compose (2 hours)
4. **Day 6**: Kafka fundamentals reading (1 hour)
5. **Day 7**: Review and practice (1 hour)

**Week 1 Before Workshop**:
1. **Day 1-2**: Kubernetes basics (2 hours)
2. **Day 3**: Confluent CLI + kcat (1 hour)
3. **Day 4**: Make + GitHub Actions overview (1 hour)
4. **Day 5-7**: Review, install all tools, test environment

---

## 📚 Essential Books to Read

### Top 3 Must-Read Books

1. **[Kafka: The Definitive Guide](https://www.confluent.io/resources/kafka-the-definitive-guide/)**
   - Authors: Neha Narkhede, Gwen Shapira, Todd Palino
   - **Free from Confluent**
   - Time: Read Chapters 1-4 (3 hours)

2. **[Designing Data-Intensive Applications](https://dataintensive.net/)**
   - Author: Martin Kleppmann
   - The bible of distributed systems
   - Time: Read Chapters 3, 5, 11 (4 hours)

3. **[Kubernetes: Up and Running](https://www.oreilly.com/library/view/kubernetes-up-and/9781492046523/)**
   - Authors: Kelsey Hightower, Brendan Burns, Joe Beda
   - Time: Read Chapters 1-5 (3 hours)

---

## 🎓 University Courses to Follow

### Free Online Courses

1. **[MIT 6.824: Distributed Systems](https://pdos.csail.mit.edu/6.824/)**
   - World-renowned distributed systems course
   - Video lectures, labs with Go
   - Time: 40+ hours (audit async)

2. **[UC Berkeley CS 194: Cloud Computing and Big Data](https://www2.eecs.berkeley.edu/Courses/CS194-24/)**
   - Covers Kafka, Spark, containers
   - Time: Full semester (audit key lectures)

3. **[Stanford CS 149: Parallel Computing](https://gfxcourses.stanford.edu/cs149/fall21)**
   - Parallel and distributed computing fundamentals
   - Time: Full semester

---

## 🌟 Expert Blogs to Follow

**Kafka & Streaming**:
- [Confluent Blog](https://www.confluent.io/blog/)
- [Martin Kleppmann](https://martin.kleppmann.com/)
- [Jay Kreps (LinkedIn)](https://www.linkedin.com/in/jaykreps/)
- [Robin Moffatt (rmoff.net)](https://rmoff.net/)

**Kubernetes & Cloud Native**:
- [Kelsey Hightower (Twitter)](https://twitter.com/kelseyhightower)
- [Brendan Burns (Microsoft)](https://azure.microsoft.com/en-us/blog/author/brendan-burns/)
- [CNCF Blog](https://www.cncf.io/blog/)

**Java & Performance**:
- [Baeldung](https://www.baeldung.com/)
- [Inside.java (Oracle)](https://inside.java/)
- [Java Code Geeks](https://www.javacodegeeks.com/)

---

## 🎬 YouTube Channels to Subscribe

1. **[Confluent](https://www.youtube.com/c/Confluent)** - Official Kafka content
2. **[TechWorld with Nana](https://www.youtube.com/c/TechWorldwithNana)** - DevOps, K8s, Docker
3. **[freeCodeCamp](https://www.youtube.com/c/Freecodecamp)** - Full courses
4. **[Traversy Media](https://www.youtube.com/c/TraversyMedia)** - Web dev and tools
5. **[DevOps Journey](https://www.youtube.com/c/DevOpsJourney)** - CI/CD, containers

---

## ✅ Final Pre-Workshop Checklist

**Environment Setup** (Run the day before workshop):
```bash
# 1. Verify Java
java -version  # Should show 17+

# 2. Verify Maven
mvn -version

# 3. Verify Docker
docker --version
docker compose version
docker ps  # Should not error

# 4. Verify Git + GitHub
git --version
ssh -T git@github.com  # Should authenticate

# 5. Clone workshop repository
git clone git@github.com:<org>/CFLT-PS-Developer-Runbook.git
cd CFLT-PS-Developer-Runbook

# 6. Run environment check
./scripts/workshop-check.sh env

# 7. Test local Kafka
make local-up
docker ps  # Should see broker and schema-registry
make local-down
```

**Reading Checklist**:
- [ ] "Kafka: The Definitive Guide" - Chapters 1-3
- [ ] Confluent Kafka 101 course (online)
- [ ] Docker Get Started tutorial
- [ ] Git basics tutorial

**Hands-On Practice** (1 hour):
- [ ] Run `docker compose up -d` with Kafka locally
- [ ] Produce and consume messages with kcat
- [ ] Create a simple Dockerfile
- [ ] Practice Git: branch, commit, push

---

## 🆘 Getting Help

**Before Workshop**:
- [Confluent Community Slack](https://launchpass.com/confluentcommunity) - Ask questions
- [Stack Overflow: apache-kafka](https://stackoverflow.com/questions/tagged/apache-kafka) - Search and ask
- Email your trainer with questions

**During Workshop**:
- Ask trainer immediately
- Check RUNBOOK.md for reference
- Collaborate with peers

---

**🎉 You're Ready!**

With these resources, you'll enter the workshop with strong foundational knowledge and be prepared to get the most out of the hands-on exercises.

**Version**: 1.0
**Last Updated**: 2026-02-11
**Maintained by**: Confluent Training Team
