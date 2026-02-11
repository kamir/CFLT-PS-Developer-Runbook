# 🎓 Confluent Developer Runbook - Student Manual

Welcome to the Confluent Cloud Java Developer Workshop! This manual will guide you through setting up your personal learning environment and tracking your progress throughout the course.

---

## 📋 Table of Contents

1. [Before You Start](#before-you-start)
2. [Getting Started](#getting-started)
3. [Creating Your Personal Branch](#creating-your-personal-branch)
4. [Setting Up Your Progress Tracker](#setting-up-your-progress-tracker)
5. [Working Through the Course](#working-through-the-course)
6. [Submitting Your Work for Review](#submitting-your-work-for-review)
7. [Course Structure Overview](#course-structure-overview)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Before You Start

### Prerequisites

Ensure you have the following installed and configured:

#### **Required Software**
- [ ] **Java 17+** (OpenJDK or Temurin)
  ```bash
  java -version  # Should show 17 or higher
  ```
- [ ] **Maven 3.9+**
  ```bash
  mvn -version
  ```
- [ ] **Docker Desktop** (or Podman)
  ```bash
  docker --version
  docker compose version
  ```
- [ ] **Git 2.30+**
  ```bash
  git --version
  ```
- [ ] **GitHub Account** with SSH key configured
  - [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

#### **Recommended Tools**
- [ ] **VS Code** or IntelliJ IDEA
- [ ] **kubectl** (for Kubernetes exercises)
  ```bash
  kubectl version --client
  ```
- [ ] **kind** (Kubernetes in Docker)
  ```bash
  kind --version
  ```
- [ ] **kcat** (Kafka CLI tool, formerly kafkacat)
  ```bash
  kcat -V
  ```

#### **System Requirements**
- **OS**: macOS, Linux, or Windows (with WSL2)
- **RAM**: Minimum 8GB, recommended 16GB
- **Disk Space**: 10GB free space
- **Network**: Stable internet connection (for Confluent Cloud access)

---

## 🏁 Getting Started

### Step 1: Fork the Repository (Optional)

If you want your own copy of the repository:

```bash
# On GitHub, click "Fork" button on the repository page
# Or use GitHub CLI:
gh repo fork <original-repo-url> --clone=false
```

### Step 2: Clone the Repository

```bash
# Clone the workshop repository
git clone git@github.com:<your-org>/CFLT-PS-Developer-Runbook.git

# Navigate into the repository
cd CFLT-PS-Developer-Runbook

# Verify you're on the main branch
git branch --show-current
```

### Step 3: Verify Your Environment

Run the environment check script:

```bash
# Make the script executable (if needed)
chmod +x scripts/workshop-check.sh

# Run environment check
./scripts/workshop-check.sh env
```

This will verify:
- Java version
- Maven installation
- Docker status
- Git configuration

---

## 🌿 Creating Your Personal Branch

**IMPORTANT**: Each student works on their own branch to avoid conflicts and track individual progress.

### Branch Naming Convention

Your branch name follows this format:
```
student/<github-username>
```

**Example**: If your GitHub username is `john-doe`, your branch is `student/john-doe`

### Create Your Branch

```bash
# Replace <your-github-username> with your actual GitHub username
export GITHUB_USERNAME="<your-github-username>"

# Create and switch to your personal branch
git checkout -b student/$GITHUB_USERNAME

# Push your branch to the remote repository
git push -u origin student/$GITHUB_USERNAME

# Verify your branch
git branch --show-current
# Should output: student/<your-github-username>
```

### ⚠️ Important Git Workflow Rules

1. **ALWAYS work on your personal branch** (`student/<your-username>`)
2. **NEVER commit directly to `main` or `develop`**
3. **Commit frequently** with clear messages
4. **Push your work daily** to backup your progress

---

## 📊 Setting Up Your Progress Tracker

Each student maintains a personalized progress tracker file. This file will track:
- Badge completion status
- Exercise completion
- Notes and reflections
- Blockers and questions

### Create Your Personal Tracker

```bash
# Set your GitHub username (if not already set)
export GITHUB_USERNAME="<your-github-username>"

# Copy the tracking template with your username
cp docs/workshop/PROGRESS_TRACKER_TEMPLATE.md "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"

# Open the file and add your details
# Edit the file with your preferred editor:
# - VS Code: code "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"
# - vim: vim "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"
# - nano: nano "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"
```

### Fill in Your Information

Open your tracker file and update the header:

```markdown
# Progress Tracker - <Your Full Name>

**GitHub Username**: <your-github-username>
**Branch**: student/<your-github-username>
**Start Date**: YYYY-MM-DD
**Target Level**: [101 / 201 / 301 / 401]
**Trainer**: <trainer-name>
```

### Commit Your Tracker

```bash
# Add your tracker file
git add "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"

# Commit with a clear message
git commit -m "Add progress tracker for ${GITHUB_USERNAME}"

# Push to your branch
git push origin student/$GITHUB_USERNAME
```

---

## 📚 Working Through the Course

### Daily Workflow

Each day/block follows this pattern:

#### 1️⃣ **Start of Day**
```bash
# Ensure you're on your branch
git checkout student/$GITHUB_USERNAME

# Pull latest changes from main (if any)
git fetch origin main
git merge origin/main

# Pull your branch updates (if working from multiple machines)
git pull origin student/$GITHUB_USERNAME
```

#### 2️⃣ **During Exercises**
```bash
# Make changes to code, configurations, etc.

# Test your changes
make test  # or specific test commands

# Commit frequently (after each logical change)
git add <changed-files>
git commit -m "Block X: Completed exercise Y - brief description"

# Example:
git commit -m "Block 2: Implemented PCI-DSS card masking in PaymentProducer"
```

#### 3️⃣ **Update Your Tracker**

After completing each block or badge, update your progress tracker:

```markdown
### Block 2: Silver Badge ✅

**Status**: Completed
**Date**: 2026-02-11
**Time Spent**: 1.5 hours

**What I Learned**:
- Implemented card number masking for PCI-DSS compliance
- Configured producer acks and idempotence
- Implemented manual offset commits for consumers

**Challenges**:
- Initially confused about offset commit timing
- Resolved by reading RUNBOOK.md section on consumer groups

**Notes**:
- Remember: `acks=all` for critical data
- `enable.idempotence=true` prevents duplicates
```

#### 4️⃣ **Commit Your Progress**
```bash
# Add your updated tracker
git add "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"

# Commit
git commit -m "Update progress: Block 2 completed (Silver Badge)"

# Push to your branch
git push origin student/$GITHUB_USERNAME
```

#### 5️⃣ **Validate Your Work**

Use the automated validation script:

```bash
# Validate specific block
./scripts/workshop-check.sh block1  # Bronze Badge
./scripts/workshop-check.sh block2  # Silver Badge
./scripts/workshop-check.sh block3  # Gold Badge
# ... and so on

# Validate complete Level 101
./scripts/workshop-check.sh final
```

---

## 📤 Submitting Your Work for Review

At the end of each level (or when requested by your trainer), submit your work via Pull Request.

### Step 1: Ensure Everything is Committed

```bash
# Check for uncommitted changes
git status

# If there are changes, commit them
git add .
git commit -m "Final cleanup for Level 101 review"

# Push to your branch
git push origin student/$GITHUB_USERNAME
```

### Step 2: Create a Pull Request

#### **Option A: Using GitHub CLI** (Recommended)

```bash
# Create PR from your branch to main
gh pr create \
  --base main \
  --head student/$GITHUB_USERNAME \
  --title "Level 101 Completion - $GITHUB_USERNAME" \
  --body "$(cat <<'EOF'
## Level Completed
**Level**: 101 - Foundations
**Student**: $GITHUB_USERNAME
**Completion Date**: $(date +%Y-%m-%d)

## Badge Summary
- [x] Bronze Badge (Block 1): Local Dev Environment
- [x] Silver Badge (Block 2): Producer/Consumer & PCI-DSS
- [x] Gold Badge (Block 3): Kafka Streams Topology
- [x] Iron Badge (Block 4): Configuration & Git-Flow
- [x] Steel Badge (Block 5): Docker & Kubernetes
- [x] Diamond Badge (Block 6): Troubleshooting

## Validation Results
\`\`\`bash
./scripts/workshop-check.sh final
# Paste output here
\`\`\`

## Trainer Review Checklist
- [ ] Code quality and style
- [ ] All badges validated
- [ ] Progress tracker complete
- [ ] Ready for Level 201

## Notes for Trainer
<!-- Add any questions or areas where you'd like specific feedback -->

EOF
)"
```

#### **Option B: Using GitHub Web Interface**

1. Go to your repository on GitHub
2. Click **"Pull requests"** → **"New pull request"**
3. Set **base**: `main` and **compare**: `student/<your-username>`
4. Click **"Create pull request"**
5. Fill in the title: `Level 101 Completion - <your-username>`
6. Use the template below for the PR description:

```markdown
## Level Completed
**Level**: 101 - Foundations
**Student**: <your-username>
**Completion Date**: YYYY-MM-DD

## Badge Summary
- [x] Bronze Badge (Block 1): Local Dev Environment
- [x] Silver Badge (Block 2): Producer/Consumer & PCI-DSS
- [x] Gold Badge (Block 3): Kafka Streams Topology
- [x] Iron Badge (Block 4): Configuration & Git-Flow
- [x] Steel Badge (Block 5): Docker & Kubernetes
- [x] Diamond Badge (Block 6): Troubleshooting

## Validation Results
```bash
./scripts/workshop-check.sh final
# Paste output here
```

## Trainer Review Checklist
- [ ] Code quality and style
- [ ] All badges validated
- [ ] Progress tracker complete
- [ ] Ready for Level 201

## Notes for Trainer
<!-- Add any questions or areas where you'd like specific feedback -->
```

### Step 3: Request Review

```bash
# Request review from your trainer (replace with trainer's GitHub username)
gh pr edit --add-reviewer <trainer-github-username>

# Or add multiple reviewers
gh pr edit --add-reviewer trainer1,trainer2
```

### Step 4: Address Feedback

If your trainer requests changes:

```bash
# Make the requested changes

# Commit and push (PR will update automatically)
git add .
git commit -m "Address review feedback: fix card masking validation"
git push origin student/$GITHUB_USERNAME

# Add a comment to the PR
gh pr comment --body "✅ Fixed card masking validation as requested"
```

### Step 5: Merge (After Approval)

Once your trainer approves:

```bash
# Trainer will typically merge, or you can merge if approved
gh pr merge <pr-number> --squash --delete-branch=false

# DON'T delete your branch - you'll continue using it for the next level
```

---

## 📖 Course Structure Overview

### **Level 101: Foundations** (1 day)
Focus: Learn Kafka fundamentals, build first applications

**Blocks & Badges**:
1. 🥉 **Bronze**: Local Dev Environment & First Messages
2. 🥈 **Silver**: Producer/Consumer Deep Dive & PCI-DSS
3. 🥇 **Gold**: Kafka Streams Topology & Fraud Detection
4. ⚙️ **Iron**: Configuration & Git-Flow
5. 🛡️ **Steel**: Docker, Kubernetes & GitOps Deployment
6. 💎 **Diamond**: Troubleshooting & Diagnostics

**Resources**:
- `docs/workshop/HANDS-ON-LAB.md` - Step-by-step guide
- `docs/workshop/AGENDA.md` - Daily schedule
- `RUNBOOK.md` - Complete reference

---

### **Level 201: Tool Mastery** (0.5 day)
Focus: Master development and deployment tools

**Blocks & Badges**:
7. 🔨 **Smith**: Build Automation (Make, Maven)
8. ⚔️ **Knight**: Local Kubernetes (kind, Helm)
9. 🔍 **Inspector**: Load Testing & Traffic Management
10. 📢 **Messenger**: CLI Tools Mastery

**Resources**:
- `docs/workshop/LEVEL-201.md` - Tool guide
- `docs/workshop/TOOLS.md` - Tool reference

---

### **Level 301: Engineering Excellence** (1 day)
Focus: Production deployment and operations

**Blocks & Badges**:
11. 🔄 **Pipeline**: CI/CD Pipeline Engineering
12. 🎖️ **Strategist**: Kubernetes Deployment Strategy
13. 📊 **Load Tester**: Load Testing & Traffic Management
14. 👨‍✈️ **Commander**: Confluent Cloud Automation
15. ⭐ **General**: End-to-End Release Simulation

**Resources**:
- `docs/workshop/LEVEL-301.md` - Workshop guide
- `.github/workflows/` - CI/CD examples

---

### **Level 401: Performance Optimization** (1 day)
Focus: Tuning and optimization for production scale

**Blocks & Badges**:
16. 🎚️ **Tuner**: Producer & Consumer Throughput
17. ⚙️ **Engineer**: Kafka Streams & RocksDB Optimization
18. 🏛️ **Architect**: K8s Resource Tuning & JVM
19. 🎖️ **Field Marshal**: Production Load Testing

**Resources**:
- `docs/workshop/LEVEL-401.md` - Optimization guide
- `tests/load/` - Load test scripts

---

## 🔧 Troubleshooting

### Common Issues

#### **Issue: Git push fails with authentication error**

```bash
# Check SSH key is configured
ssh -T git@github.com

# If using HTTPS, switch to SSH
git remote set-url origin git@github.com:<org>/<repo>.git
```

#### **Issue: Branch already exists remotely**

```bash
# Delete remote branch and recreate (ONLY if you're sure)
git push origin --delete student/$GITHUB_USERNAME
git push -u origin student/$GITHUB_USERNAME
```

#### **Issue: Merge conflicts when pulling from main**

```bash
# Check what files have conflicts
git status

# Edit conflicting files, then:
git add <resolved-files>
git commit -m "Resolve merge conflicts with main"
```

#### **Issue: Progress tracker template not found**

```bash
# Check if template exists
ls -la docs/workshop/PROGRESS_TRACKER_TEMPLATE.md

# If missing, ask your trainer or create from scratch using the example
```

#### **Issue: Workshop validation fails**

```bash
# Check specific block requirements
./scripts/workshop-check.sh block1 --verbose

# Review RUNBOOK.md for detailed requirements
# Ask trainer for help if needed
```

---

## 📞 Getting Help

### During the Workshop

1. **Check RUNBOOK.md** - Comprehensive reference for all topics
2. **Ask your trainer** - Don't hesitate to raise your hand
3. **Collaborate with peers** - Discuss concepts, but write your own code
4. **Use workshop Slack channel** - Post questions and share solutions

### After the Workshop

1. **Review course materials** - All docs are in `/docs/workshop/`
2. **Confluent Documentation** - https://docs.confluent.io
3. **Community Support** - Confluent Community Slack
4. **Stack Overflow** - Tag questions with `apache-kafka` and `confluent`

---

## 🎯 Tips for Success

### Best Practices

1. **Commit early, commit often** - Small, logical commits are easier to review
2. **Write clear commit messages** - Explain *why*, not just *what*
3. **Update your tracker daily** - Helps with retention and reflection
4. **Test before committing** - Run `make test` or specific tests
5. **Push daily** - Backup your work and show progress
6. **Ask questions** - There are no stupid questions
7. **Take breaks** - Pomodoro technique: 25 min work, 5 min break

### Commit Message Examples

**Good**:
```
Block 2: Implement PCI-DSS card masking in PaymentProducer

- Mask middle 8 digits of card numbers
- Add regex validation for card format
- Update tests to verify masking
```

**Bad**:
```
fix stuff
```

### Time Management

**Level 101** (1 day):
- Block 1-2: ~2 hours (morning)
- Block 3-4: ~2 hours (afternoon)
- Block 5-6: ~2 hours (late afternoon)

**Level 201** (0.5 day):
- Block 7-10: ~4 hours (can be split across days)

**Level 301** (1 day):
- Block 11-15: ~6-7 hours

**Level 401** (1 day):
- Block 16-19: ~6-7 hours

---

## 📜 Certification

### Badge Validation

Each badge is validated by:
1. **Automated checks** - `./scripts/workshop-check.sh`
2. **Code review** - Trainer review of your PR
3. **Knowledge check** - Questions in LERNPFAD.md

### Certification Levels

- **Level 101**: Master Badge (all 6 badges)
- **Level 201**: Tool Master Badge (all 4 badges)
- **Level 301**: Workshop Master Badge (all 5 badges)
- **Level 401**: Grand Master Badge (all 4 badges)

### After Completion

1. **Update your resume/LinkedIn** - List badges earned
2. **Share your code** - Your branch is your portfolio
3. **Keep learning** - Apply skills to real projects
4. **Give feedback** - Help improve the course

---

## 🙏 Acknowledgments

Thank you for participating in the Confluent Cloud Java Developer Workshop!

This workshop is designed to give you hands-on experience with production-grade Kafka development. Apply these skills to build robust, scalable, and compliant streaming applications.

**Happy Coding!** 🚀

---

**Questions?** Contact your trainer or create an issue in this repository.

**Version**: 1.0
**Last Updated**: 2026-02-11
