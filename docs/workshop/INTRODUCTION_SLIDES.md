---
marp: true
theme: default
paginate: true
backgroundColor: #fff
backgroundImage: url('https://marp.app/assets/hero-background.svg')
style: |
  section {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }
  h1 {
    color: #0066cc;
  }
  h2 {
    color: #0099ff;
  }
  code {
    background-color: #f4f4f4;
    padding: 2px 6px;
    border-radius: 3px;
  }
---

# 🎓 Confluent Developer Workshop
## Welcome!

**Building Production-Ready Kafka Applications**

Trainer: [Your Name]
Date: [Workshop Date]

---

## 👋 Welcome & Introductions

### About Me
- [Your background]
- [Your Kafka experience]
- [Contact information]

### About You
- Name and role
- Experience with Kafka?
- What do you hope to learn?

**Let's go around the room!** (or Zoom chat)

---

## 📋 Workshop Overview

### What You'll Learn
✅ Build Kafka applications (Producer, Consumer, Streams)
✅ Deploy to Kubernetes with Docker
✅ Set up CI/CD pipelines
✅ Troubleshoot and optimize Kafka systems

### What You'll Build
A **PCI-DSS compliant payment processing pipeline**:
- Payment event producer
- Fraud detection with Kafka Streams
- Containerized deployments
- Production-ready CI/CD

---

## 🎯 Course Structure: 4 Levels

### 📚 Level 101: Foundations (1 day)
**6 Badges**: Bronze → Silver → Gold → Iron → Steel → Diamond
**Focus**: Learn Kafka fundamentals, build first applications

### 🔧 Level 201: Tool Mastery (0.5 day)
**4 Badges**: Smith → Knight → Inspector → Messenger
**Focus**: Master development and deployment tools

### 🏗️ Level 301: Engineering Excellence (1 day)
**5 Badges**: Pipeline → Strategist → Load Tester → Commander → General
**Focus**: Production deployment and operations

### ⚡ Level 401: Performance Optimization (1 day)
**4 Badges**: Tuner → Engineer → Architect → Field Marshal
**Focus**: Tuning and optimization for production scale

---

## 🎖️ Badge System

### How It Works
- Complete exercises for each block
- Earn badges for completed blocks
- Track progress in your personal tracker
- Submit work via Pull Request
- Trainer reviews and approves

### Certifications
- **Level 101**: Master Badge (6 badges)
- **Level 201**: Tool Master Badge (4 badges)
- **Level 301**: Workshop Master Badge (5 badges)
- **Level 401**: Grand Master Badge (4 badges)

---

## 📅 Today's Schedule (Level 101)

| Time | Block | Badge | Topic |
|------|-------|-------|-------|
| 09:00-09:30 | Setup | - | Environment & Branches |
| 09:30-10:30 | Block 1 | 🥉 Bronze | Local Dev & First Messages |
| 10:45-12:00 | Block 2 | 🥈 Silver | Producer/Consumer & PCI-DSS |
| 13:00-14:15 | Block 3 | 🥇 Gold | Kafka Streams & Fraud Detection |
| 14:30-15:45 | Block 4 | ⚙️ Iron | Configuration & Git-Flow |
| 16:00-16:45 | Block 5 | 🛡️ Steel | Docker & Kubernetes |
| 16:45-17:00 | Block 6 | 💎 Diamond | Troubleshooting |

**Breaks**: 15 min mid-morning, 1 hour lunch, 15 min mid-afternoon

---

## 🌿 Your Personal Branch Workflow

### How This Works
1. **Clone** the repository
2. **Create** your personal branch: `student/<your-github-username>`
3. **Work** on exercises on your branch
4. **Track** progress in your personalized tracker
5. **Commit** and **push** frequently
6. **Submit** PR at end of each level for review

### Why Personal Branches?
✅ No merge conflicts
✅ Clean audit trail
✅ Portfolio-ready code
✅ Individual pacing

---

## 🚀 Getting Started: Step 1

### Prerequisites Check

Open your terminal and run:

```bash
java -version     # Should show 17+
mvn -version      # Should show 3.9+
docker --version  # Should work
git --version     # Should work
docker ps         # Should not error
```

**Issues?** Raise your hand (or message in chat)

---

## 🚀 Getting Started: Step 2

### Clone Repository

```bash
# Clone the workshop repo
git clone git@github.com:<org>/CFLT-PS-Developer-Runbook.git

# Navigate into it
cd CFLT-PS-Developer-Runbook

# Verify you're on main
git branch --show-current
```

---

## 🚀 Getting Started: Step 3

### Create Your Branch

```bash
# Set your GitHub username
export GITHUB_USERNAME="<your-github-username>"

# Create and push your branch
git checkout -b student/$GITHUB_USERNAME
git push -u origin student/$GITHUB_USERNAME

# Verify
git branch --show-current
# Should show: student/<your-username>
```

**✅ Checkpoint**: Trainer will verify all branches created

---

## 🚀 Getting Started: Step 4

### Create Your Progress Tracker

```bash
# Copy the template
cp docs/workshop/PROGRESS_TRACKER_TEMPLATE.md \
   "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"

# Edit it (add your name, start date, etc.)
# Use your favorite editor: code, vim, nano

# Commit and push
git add "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"
git commit -m "Add progress tracker for ${GITHUB_USERNAME}"
git push origin student/$GITHUB_USERNAME
```

---

## 📖 Important Documents

### For Students
- **STUDENT_MANUAL.md** - Complete workflow guide
- **docs/TOOLS_WARMUP.md** - Pre-workshop learning resources
- **docs/COURSE_STRUCTURE.md** - Level structure explained
- **RUNBOOK.md** - Complete developer reference

### During Workshop
- **docs/workshop/HANDS-ON-LAB.md** - Step-by-step Level 101 guide
- **docs/workshop/LERNPFAD.md** - Learning path with knowledge checks

### For Trainers
- **docs/COACH_GUIDE.md** - Trainer procedures

---

## 🔧 Tools We'll Use Today

### Core Development
- **Java 17** - Application development
- **Maven** - Build tool
- **Git & GitHub** - Version control

### Kafka Tools
- **kcat** - Message inspection
- **Confluent CLI** - Cloud management
- **Kafka CLI** - Topic/consumer operations

### Containerization
- **Docker** - Containerization
- **Kubernetes** - Orchestration
- **kind** - Local K8s clusters

---

## 🎯 Learning Philosophy

### 80% Hands-On, 20% Lecture
- You learn by DOING
- I'll demo, then you try
- Ask questions freely
- Help your neighbors

### Individual Work, Collaborative Learning
- Work on your own branch
- Discuss concepts with others
- Don't copy code, but share ideas

### Mistakes Are Learning Opportunities
- Errors are expected
- Debugging is a key skill
- We learn together

---

## 💡 Tips for Success

### Commit Frequently
```bash
# After each logical change:
git add <files>
git commit -m "Block 2: Implement card masking"
git push origin student/$GITHUB_USERNAME
```

### Update Your Tracker Daily
- Document what you learned
- Note challenges and solutions
- Track your progress

### Ask Questions
- No question is "stupid"
- Asking helps everyone
- Use chat for quick questions

---

## 📞 Getting Help

### During Workshop
1. **Try it yourself first** (5-10 min)
2. **Check RUNBOOK.md** or docs
3. **Ask your neighbor**
4. **Raise your hand** (or message in chat)
5. **Ask the trainer**

### After Workshop
- Slack: `#workshop-confluent-dev`
- Email: [trainer email]
- Office hours: [if applicable]

---

## 🎓 Workshop Rules

### Do's ✅
- Work on your personal branch
- Commit often with clear messages
- Update your progress tracker
- Help your peers (discuss, don't copy)
- Take breaks when needed

### Don'ts ❌
- Don't push to `main` or `develop`
- Don't commit secrets/credentials
- Don't skip updating your tracker
- Don't hesitate to ask questions

---

## 🏆 Success Criteria

### Level 101 Completion
- ✅ All 6 badges earned
- ✅ PR submitted and approved
- ✅ Progress tracker complete
- ✅ Code quality meets standards
- ✅ Validation script passes

### What Happens After?
- Receive **Master Badge** certification
- Access to Level 201 materials
- Invitation to advanced workshops
- Your branch = your portfolio

---

## 🔥 Let's Get Started!

### Block 1: Bronze Badge 🥉
**Local Dev Environment & First Messages**

In this block, you'll:
- Start Kafka locally with Docker Compose
- Create your first topic
- Produce and consume messages with kcat
- Understand partitions and offsets

**Time**: 60 minutes
**Resource**: `docs/workshop/HANDS-ON-LAB.md` - Block 1

**Ready?** Let's go! 🚀

---

## 🎉 End of Introduction

### Questions?

---

<!-- BLOCK INTRODUCTION SLIDES -->

---

# 🥉 Block 1: Bronze Badge
## Local Dev Environment & First Messages

**Learning Objectives**:
- Set up local Kafka with Docker Compose
- Understand topics, partitions, offsets
- Produce and consume messages with kcat

**Time**: 60 minutes

---

## 🥉 Block 1: What You'll Do

### Step 1: Start Local Kafka
```bash
make local-up
```

### Step 2: Create a Topic
```bash
kcat -b localhost:9092 -L
```

### Step 3: Produce Messages
```bash
echo "test-key|test-value" | kcat -b localhost:9092 -t payments -P -K "|"
```

### Step 4: Consume Messages
```bash
kcat -b localhost:9092 -t payments -C
```

---

## 🥉 Block 1: Key Concepts

### Topics
- Named stream of events
- Like a table in a database, but append-only

### Partitions
- Topics are divided into partitions
- Allows parallel processing
- Each message goes to one partition

### Offsets
- Sequence number within a partition
- Monotonically increasing
- Consumer tracks its position via offset

---

# 🥈 Block 2: Silver Badge
## Producer/Consumer Deep Dive & PCI-DSS

**Learning Objectives**:
- Implement Kafka producer with Avro
- Add PCI-DSS compliant card masking
- Implement consumer with manual offset commits

**Time**: 75 minutes

---

# 🥇 Block 3: Gold Badge
## Kafka Streams Topology & Fraud Detection

**Learning Objectives**:
- Build Kafka Streams topology
- Implement branching logic
- Write tests with TopologyTestDriver

**Time**: 75 minutes

---

# ⚙️ Block 4: Iron Badge
## Configuration & Git-Flow

**Learning Objectives**:
- Understand 5-layer config resolution
- Create environment-specific configs
- Learn Git-Flow branching strategy

**Time**: 75 minutes

---

# 🛡️ Block 5: Steel Badge
## Docker, Kubernetes & GitOps

**Learning Objectives**:
- Build Docker images with multi-stage builds
- Deploy to Kubernetes with kind
- Use Kustomize for environment overlays

**Time**: 60 minutes

---

# 💎 Block 6: Diamond Badge
## Troubleshooting & Diagnostics

**Learning Objectives**:
- Diagnose connectivity issues
- Check consumer lag
- Debug schema compatibility
- Use JMX metrics

**Time**: 30 minutes

---

# 🎉 Level 101 Complete!

## Submit Your Work

1. **Ensure everything is committed**:
   ```bash
   git status
   git add .
   git commit -m "Level 101 complete"
   git push origin student/$GITHUB_USERNAME
   ```

2. **Run final validation**:
   ```bash
   ./scripts/workshop-check.sh final
   ```

3. **Create Pull Request**:
   ```bash
   gh pr create --base main --head student/$GITHUB_USERNAME \
     --title "Level 101 Completion - $GITHUB_USERNAME"
   ```

---

# 🎊 Congratulations!

### What You Accomplished Today
✅ Built producer/consumer applications
✅ Implemented Kafka Streams topology
✅ Deployed to Kubernetes
✅ Mastered configuration management
✅ Gained troubleshooting skills

### Next Steps
- Review your progress tracker
- Wait for trainer PR review
- Prepare for Level 201!

---

# 📚 Additional Resources

### Official Documentation
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Documentation](https://docs.confluent.io/)

### Learning
- [Confluent Developer](https://developer.confluent.io/)
- [Kafka: The Definitive Guide](https://www.confluent.io/resources/kafka-the-definitive-guide/) (FREE)

### Community
- Confluent Community Slack
- Stack Overflow: `apache-kafka`

---

# 🙏 Thank You!

## Questions?

**Contact**: [trainer-email]
**Slack**: #workshop-confluent-dev
**Office Hours**: [if applicable]

---

**Session Link**: https://claude.ai/code/session_01Qitwokcudi4tLnD4wBqwP3
