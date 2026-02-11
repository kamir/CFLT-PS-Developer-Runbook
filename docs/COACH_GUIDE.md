# 🎓 Confluent Developer Runbook - Coach Guide

## Overview

This guide provides comprehensive instructions for trainers/coaches running the Confluent Cloud Java Developer Workshop. It covers student onboarding, progress tracking, review procedures, and workshop management.

---

## 📋 Table of Contents

1. [Workshop Structure](#workshop-structure)
2. [Pre-Workshop Preparation](#pre-workshop-preparation)
3. [Student Onboarding Procedure](#student-onboarding-procedure)
4. [Daily Workshop Flow](#daily-workshop-flow)
5. [Student Branch Management](#student-branch-management)
6. [Progress Tracking & Review](#progress-tracking--review)
7. [Pull Request Review Process](#pull-request-review-process)
8. [Troubleshooting Common Issues](#troubleshooting-common-issues)
9. [Post-Workshop Activities](#post-workshop-activities)
10. [Appendix: Scripts & Automation](#appendix-scripts--automation)

---

## 🏗️ Workshop Structure

### Course Levels

| Level | Duration | Focus | Certification |
|-------|----------|-------|---------------|
| **101** | 1 day (8h) | Foundations - Kafka basics, first applications | Master Badge (6 badges) |
| **201** | 0.5 day (4h) | Tool Mastery - Build, test, deploy tools | Tool Master Badge (4 badges) |
| **301** | 1 day (6-7h) | Engineering Excellence - CI/CD, production deployment | Workshop Master Badge (5 badges) |
| **401** | 1 day (6-7h) | Performance Optimization - Tuning, capacity planning | Grand Master Badge (4 badges) |

### Workshop Delivery Options

**Option 1: Full Intensive (4 days)**
- Day 1: Level 101
- Day 2: Level 201 (morning) + Level 301 (afternoon)
- Day 3: Level 301 (continued)
- Day 4: Level 401

**Option 2: Fundamentals (1.5 days)**
- Day 1: Level 101
- Day 2 (morning): Level 201

**Option 3: Weekly Sessions (4 weeks)**
- Week 1: Level 101 (1 day)
- Week 2: Level 201 (half day) + self-study
- Week 3: Level 301 (1 day)
- Week 4: Level 401 (1 day)

---

## 📝 Pre-Workshop Preparation

### 1-2 Weeks Before Workshop

#### **Setup Repository Access**

1. **Ensure repository is accessible**:
   ```bash
   # Verify repository is public or students have access
   gh repo view <org>/<repo> --json visibility

   # If private, invite students:
   gh api repos/<org>/<repo>/collaborators/<username> -X PUT
   ```

2. **Create workshop branch protection rules**:
   ```bash
   # Protect main branch
   gh api repos/<org>/<repo>/branches/main/protection -X PUT \
     --field required_pull_request_reviews[required_approving_review_count]=1 \
     --field required_pull_request_reviews[dismiss_stale_reviews]=true

   # Allow student/* branches to be created
   # (No protection needed for student branches)
   ```

3. **Verify all workshop materials are up to date**:
   - [ ] STUDENT_MANUAL.md exists
   - [ ] PROGRESS_TRACKER_TEMPLATE.md exists
   - [ ] docs/workshop/HANDS-ON-LAB.md is current
   - [ ] docs/workshop/LERNPFAD.md has all badges
   - [ ] scripts/workshop-check.sh is executable and works
   - [ ] All code examples compile and run

#### **Prepare Student List**

Create a student roster:
```csv
# students.csv
full_name,github_username,email,level
John Doe,johndoe,john.doe@example.com,101
Jane Smith,janesmith,jane.smith@example.com,101-301
```

#### **Send Pre-Workshop Email**

Subject: **Confluent Developer Workshop - Preparation Required**

```
Hi [Student Name],

Welcome to the Confluent Cloud Java Developer Workshop!

BEFORE THE WORKSHOP:

📖 REQUIRED PREPARATION (4-8 hours recommended, 2 weeks before workshop):

1. **Tools Warm-Up** (HIGHLY RECOMMENDED):
   Complete our comprehensive pre-workshop learning guide:
   👉 docs/TOOLS_WARMUP.md

   This includes:
   - High-quality tutorials from vendors, universities, and experts
   - Hands-on exercises for Java, Git, Docker, Kafka
   - Interactive learning resources
   - Recommended reading: "Kafka: The Definitive Guide" (FREE)

   Minimum: 4 hours (Java, Maven, Git, Docker, Kafka basics)
   Recommended: 8 hours (includes Kubernetes, CLI tools)

2. **Install Prerequisites** (1 hour):
   - Java 17+ installed
   - Maven 3.9+ installed
   - Docker Desktop installed and running
   - Git installed
   - GitHub account with SSH key configured

3. **Clone & Test Repository** (30 minutes):
   ```
   git clone git@github.com:<org>/CFLT-PS-Developer-Runbook.git
   cd CFLT-PS-Developer-Runbook
   ./scripts/workshop-check.sh env
   ```

4. **Read Documentation**:
   - STUDENT_MANUAL.md - Workshop workflow
   - docs/COURSE_STRUCTURE.md - Level structure and badges

OPTIONAL BUT RECOMMENDED:
- Complete Confluent Kafka 101 course: https://developer.confluent.io/learn-kafka/
- Set up Confluent Cloud free trial: https://www.confluent.io/confluent-cloud/tryfree/

If you encounter any issues, please reply to this email ASAP.

Looking forward to seeing you on [Workshop Date] at [Time]!

Best regards,
[Your Name]
Confluent Trainer
```

#### **Setup Confluent Cloud Environment** (if using cloud)

```bash
# Run setup script
./scripts/ccloud-setup.sh

# Create API keys for students (if shared cluster)
# OR provide instructions for students to create their own environments
```

#### **Prepare Workshop Slack Channel** (optional)

Create a dedicated Slack channel: `#workshop-confluent-dev-YYYY-MM`
- Pin important links (repo, docs, troubleshooting)
- Set channel topic with workshop dates and schedule

---

## 👨‍🎓 Student Onboarding Procedure

### Day 1 - Morning (Before Starting Block 1)

#### **Step 1: Welcome & Introduction (15 min)**

1. Introduce yourself and the workshop structure
2. Share daily schedule and break times
3. Explain badge system and certification
4. Set expectations:
   - Hands-on learning (80% coding, 20% lecture)
   - Collaborative but individual work
   - Ask questions freely
   - Take breaks when needed

#### **Step 2: Verify Student Prerequisites (15 min)**

**Run environment check as a group**:
```bash
./scripts/workshop-check.sh env
```

**Common issues**:
- Docker not running: `docker ps`
- Java version wrong: `java -version`
- Maven not found: `mvn -version`

**Have students report status**:
- ✅ All green: Ready to go
- ⚠️ Some issues: Help during break
- ❌ Major issues: Pair with ready student, fix offline

#### **Step 3: Create Personal Branches (15 min)**

**Guide students through branch creation**:

```bash
# Have each student run:
export GITHUB_USERNAME="<their-github-username>"
git checkout -b student/$GITHUB_USERNAME
git push -u origin student/$GITHUB_USERNAME
```

**Verify all branches created**:
```bash
# As trainer, verify:
git fetch --all
git branch -r | grep student/

# Should see all student branches
```

**Create a branch tracking sheet** (Google Sheets or similar):
```
Student Name | GitHub Username | Branch Name | Status
John Doe     | johndoe         | student/johndoe | ✅ Created
Jane Smith   | janesmith       | student/janesmith | ✅ Created
```

#### **Step 4: Setup Progress Trackers (10 min)**

**Guide students through tracker setup**:

```bash
# Each student runs:
export GITHUB_USERNAME="<their-github-username>"
cp docs/workshop/PROGRESS_TRACKER_TEMPLATE.md "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"

# Edit the file to add their information
# Then commit:
git add "docs/workshop/PROGRESS_TRACKER_${GITHUB_USERNAME}.md"
git commit -m "Add progress tracker for ${GITHUB_USERNAME}"
git push origin student/$GITHUB_USERNAME
```

**Verify all trackers created**:
```bash
# As trainer:
git fetch --all

# Check each student branch:
for branch in $(git branch -r | grep student/); do
  echo "Checking $branch"
  git show $branch:docs/workshop/PROGRESS_TRACKER_*.md > /dev/null 2>&1 && echo "✅ Tracker exists" || echo "❌ No tracker"
done
```

#### **Step 5: Quick Git Workflow Review (5 min)**

**Emphasize**:
```bash
# ALWAYS work on your branch
git checkout student/$GITHUB_USERNAME

# Commit often
git add <files>
git commit -m "Clear message"

# Push daily
git push origin student/$GITHUB_USERNAME

# NEVER push to main
```

---

## 📅 Daily Workshop Flow

### Standard Daily Schedule (Level 101 Example)

| Time | Activity | Duration |
|------|----------|----------|
| 09:00-09:15 | Welcome & Daily Goals | 15 min |
| 09:15-10:30 | Block 1: Bronze Badge | 75 min |
| 10:30-10:45 | Break | 15 min |
| 10:45-12:00 | Block 2: Silver Badge | 75 min |
| 12:00-13:00 | Lunch | 60 min |
| 13:00-14:15 | Block 3: Gold Badge | 75 min |
| 14:15-14:30 | Break | 15 min |
| 14:30-15:45 | Block 4: Iron Badge | 75 min |
| 15:45-16:00 | Break | 15 min |
| 16:00-16:45 | Block 5: Steel Badge | 45 min |
| 16:45-17:00 | Block 6: Diamond Badge | 15 min |
| 17:00-17:15 | Daily Wrap-up & Q&A | 15 min |

### Morning Routine (15 min)

**Start each day with**:

1. **Quick Stand-up** (5 min):
   - "What did we learn yesterday?"
   - "What are we learning today?"
   - "Any blockers from yesterday?"

2. **Daily Goals** (5 min):
   - Review today's badges
   - Highlight key learning objectives
   - Set expectations for pace

3. **Environment Check** (5 min):
   - "Everyone on their student branch?"
   - "Any issues from yesterday?"
   - "Docker/tools still working?"

### Block Delivery Pattern

**Each block (60-90 min)**:

1. **Intro** (5-10 min):
   - Explain the badge/topic
   - Show real-world use case
   - Connect to previous blocks

2. **Demo** (10-15 min):
   - Live code demonstration
   - Explain key concepts as you go
   - Highlight common pitfalls

3. **Hands-on Exercise** (30-50 min):
   - Students work independently or in pairs
   - Circulate to answer questions
   - Help debug issues

4. **Validation** (5-10 min):
   - Run workshop-check.sh for the block
   - Review common mistakes
   - Share solutions to tricky parts

5. **Wrap-up** (5 min):
   - Review what was learned
   - Preview next block
   - Answer final questions

### End of Day Routine (15 min)

1. **Progress Check**:
   ```bash
   # Ask students to update trackers
   # Verify everyone has committed and pushed
   ```

2. **Quick Retro**:
   - "Roses" (what went well)
   - "Thorns" (what was challenging)
   - "Buds" (what you're excited about tomorrow)

3. **Homework** (if multi-day workshop):
   - "Finish any incomplete badges"
   - "Read ahead in RUNBOOK.md for tomorrow's topics"
   - "Update your progress tracker"

---

## 🌿 Student Branch Management

### Branch Naming Convention

**Strict convention**:
```
student/<github-username>
```

**Examples**:
- `student/johndoe`
- `student/jane-smith`
- `student/alex123`

### Monitoring Student Branches

#### **List All Student Branches**
```bash
git fetch --all
git branch -r | grep student/
```

#### **Check Last Activity on Each Branch**
```bash
#!/bin/bash
# save as scripts/check-student-activity.sh

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  echo "=== $branch ==="
  git log --oneline --max-count=5 origin/$branch
  echo ""
done
```

#### **Verify Tracker Exists on Each Branch**
```bash
#!/bin/bash
# save as scripts/verify-trackers.sh

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')
  tracker="docs/workshop/PROGRESS_TRACKER_${username}.md"

  git show "origin/$branch:$tracker" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✅ $branch: Tracker exists"
  else
    echo "❌ $branch: No tracker found"
  fi
done
```

### Helping Students with Git Issues

#### **Student pushed to wrong branch**
```bash
# As student:
git checkout student/$GITHUB_USERNAME
git cherry-pick <commit-hash>
git push origin student/$GITHUB_USERNAME

# Then remove bad commit from wrong branch (if needed)
```

#### **Student has merge conflicts**
```bash
# As student:
git checkout student/$GITHUB_USERNAME
git fetch origin main
git merge origin/main

# Resolve conflicts in editor
git add <resolved-files>
git commit -m "Resolve merge conflicts with main"
git push origin student/$GITHUB_USERNAME
```

#### **Student lost work (no commits)**
```bash
# Check if work is in stash
git stash list

# Or check reflog
git reflog

# Recover if found
git stash apply
# or
git reset --hard <commit-hash-from-reflog>
```

---

## 📊 Progress Tracking & Review

### Tracking Student Progress

#### **Option 1: Manual Tracking Spreadsheet**

Create a Google Sheet:
```
Student | Block1 | Block2 | Block3 | Block4 | Block5 | Block6 | Level101 PR | Status
--------|--------|--------|--------|--------|--------|--------|-------------|-------
John    |   ✅   |   ✅   |   🔄   |   ⬜   |   ⬜   |   ⬜   |             | In Progress
Jane    |   ✅   |   ✅   |   ✅   |   ✅   |   ⬜   |   ⬜   |             | In Progress
```

#### **Option 2: Automated Progress Checks**

```bash
#!/bin/bash
# scripts/coach-check-all-students.sh

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')
  echo "=== Checking $username ==="

  # Checkout branch
  git checkout $branch 2>/dev/null

  # Run validation (assumes script works on any branch)
  ./scripts/workshop-check.sh block1
  ./scripts/workshop-check.sh block2
  ./scripts/workshop-check.sh block3

  echo ""
done

git checkout main
```

#### **Option 3: Review Progress Trackers**

```bash
#!/bin/bash
# scripts/review-trackers.sh

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')
  tracker="docs/workshop/PROGRESS_TRACKER_${username}.md"

  echo "=== $username ==="
  git show "origin/$branch:$tracker" | grep "Status:" | head -10
  echo ""
done
```

### Daily Progress Checkpoints

**End of each day**:

1. **Check commits**:
   ```bash
   # Verify all students have pushed today
   ./scripts/check-student-activity.sh
   ```

2. **Review trackers**:
   ```bash
   # Quick scan of progress trackers
   ./scripts/review-trackers.sh
   ```

3. **Identify stragglers**:
   - Who hasn't completed expected badges?
   - Who needs extra help tomorrow?

4. **Send encouragement** (optional):
   ```
   Quick Slack message:
   "Great work today team! 🎉

   If you haven't finished Blocks 1-3, please complete them tonight.
   Remember to update your progress tracker and push your work!

   See you tomorrow at 9am!"
   ```

---

## 🔍 Pull Request Review Process

### When Students Submit PRs

Students submit PRs at the end of each level (or as you specify).

### PR Review Checklist

#### **Step 1: Initial Validation**

When a PR is created:
```bash
# Fetch the branch
git fetch origin student/<username>

# Checkout the branch
git checkout student/<username>

# Run automated validation
./scripts/workshop-check.sh final  # for Level 101
# or specific level checks

# Build and test
make build
make test
```

#### **Step 2: Code Review**

**Level 101 Review Checklist**:

- [ ] **Block 1 (Bronze)**:
  - [ ] Can produce messages to Kafka topic
  - [ ] Can consume messages from topic
  - [ ] Demonstrates understanding of partitions/offsets

- [ ] **Block 2 (Silver)**:
  - [ ] PaymentProducer correctly implements card masking
  - [ ] Producer has appropriate configs (acks, idempotence)
  - [ ] Consumer implements manual offset commits
  - [ ] PCI-DSS compliance demonstrated

- [ ] **Block 3 (Gold)**:
  - [ ] Kafka Streams topology correctly implements branching
  - [ ] Fraud detection logic is sound
  - [ ] TopologyTestDriver tests pass
  - [ ] Code is well-structured

- [ ] **Block 4 (Iron)**:
  - [ ] Environment-specific configs (dev/qa/prod) are correct
  - [ ] Config loading works properly
  - [ ] Sensitive data is parameterized

- [ ] **Block 5 (Steel)**:
  - [ ] Dockerfile uses multi-stage build
  - [ ] PCI-DSS hardening applied (non-root user, minimal base)
  - [ ] Kubernetes manifests are correct
  - [ ] Kustomize overlays work

- [ ] **Block 6 (Diamond)**:
  - [ ] Demonstrates diagnostic capabilities
  - [ ] Can identify and fix common issues

- [ ] **Overall**:
  - [ ] Code quality (readable, follows conventions)
  - [ ] Commit messages are clear
  - [ ] Progress tracker is complete and reflective
  - [ ] All tests pass

#### **Step 3: Provide Feedback**

**Feedback Template**:
```markdown
## Level 101 Review - @<username>

### ✅ Strengths
- Great implementation of card masking with regex pattern
- Well-organized code structure
- Excellent commit messages

### 🔄 Requested Changes
1. **Block 2**: Producer acks should be "all" not "1" for critical data
   - File: `producer-consumer-app/src/main/resources/application-prod.properties`
   - Change: `acks=all`

2. **Block 3**: Add error handling in fraud detection topology
   - File: `kstreams-app/src/main/java/.../FraudDetectionTopology.java`
   - Add try-catch around transaction amount parsing

### 💡 Suggestions (Optional)
- Consider adding more comprehensive test cases for edge scenarios
- Great job on documentation in your progress tracker!

### Next Steps
Please address the requested changes and push updates to your branch.
I'll re-review once you comment "Ready for re-review".

Keep up the great work! 🎉
```

#### **Step 4: Approve or Request Changes**

**If everything looks good**:
```bash
# Approve via GitHub CLI
gh pr review <pr-number> --approve --body "Great work! Level 101 complete. ✅ Master Badge earned!"

# Merge (but don't delete branch - needed for next level)
gh pr merge <pr-number> --squash --delete-branch=false
```

**If changes needed**:
```bash
# Request changes
gh pr review <pr-number> --request-changes --body "<feedback from template>"
```

### Managing Multiple PRs

**Script to list all pending PRs**:
```bash
#!/bin/bash
# scripts/list-student-prs.sh

gh pr list --label "workshop" --state open --json number,author,title,createdAt
```

**Batch review status**:
```bash
#!/bin/bash
# scripts/pr-review-status.sh

for pr in $(gh pr list --label "workshop" --state open --json number --jq '.[].number'); do
  echo "=== PR #$pr ==="
  gh pr view $pr --json title,author,reviewDecision,reviews
  echo ""
done
```

---

## 🛠️ Troubleshooting Common Issues

### Student Environment Issues

#### **Docker not running**
```bash
# macOS/Windows
# Ask student to start Docker Desktop

# Linux
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in
```

#### **Java version mismatch**
```bash
# Check Java version
java -version

# If wrong, install Java 17:
# macOS:
brew install openjdk@17

# Ubuntu:
sudo apt-get install openjdk-17-jdk

# Set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 17)  # macOS
# or
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Linux
```

#### **Maven build fails**
```bash
# Clear Maven cache
rm -rf ~/.m2/repository

# Rebuild
mvn clean install -U
```

### Git Workflow Issues

#### **Student can't push (403 Forbidden)**
```bash
# Check remote URL
git remote -v

# If HTTPS, switch to SSH
git remote set-url origin git@github.com:<org>/<repo>.git

# Verify SSH key
ssh -T git@github.com
```

#### **Student committed secrets/credentials**
```bash
# Remove secret from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret/file' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (BE CAREFUL - only on student branch)
git push --force origin student/$GITHUB_USERNAME
```

### Application Issues

#### **Producer can't connect to broker**
```bash
# Check Docker is running
docker ps

# Check broker is accessible
docker logs broker

# Test connection
kcat -b localhost:9092 -L
```

#### **Consumer lag not decreasing**
```bash
# Check consumer group
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group payment-consumer-group --describe

# Check for errors in consumer logs
```

#### **Kafka Streams app not starting**
```bash
# Check state store directory permissions
ls -la /tmp/kafka-streams/

# Check logs
tail -f logs/kstreams-app.log

# Common issue: stale state store
rm -rf /tmp/kafka-streams/*
```

---

## 📝 Post-Workshop Activities

### End of Workshop (Last Day)

#### **Final Certification Review**

1. **Verify all badges earned**:
   ```bash
   ./scripts/verify-all-badges.sh
   ```

2. **Export student results**:
   ```bash
   # Create a summary report
   ./scripts/generate-workshop-report.sh > workshop-summary-YYYY-MM-DD.md
   ```

3. **Issue certificates** (if applicable):
   - Generate certificate PDFs
   - Email to students
   - Post on LinkedIn (with student permission)

#### **Collect Feedback**

**Send feedback survey**:
```
Subject: Workshop Feedback - Help Us Improve!

Hi [Student Name],

Thank you for completing the Confluent Developer Workshop!

Please take 5 minutes to provide feedback:
[Link to Google Form]

Topics:
- Overall satisfaction
- Pace and difficulty
- Materials quality
- Trainer effectiveness
- Suggestions for improvement

Your feedback helps us improve future workshops.

Congratulations on your certification!

Best regards,
[Trainer Name]
```

**Feedback form questions**:
1. Overall workshop rating (1-5 stars)
2. Was the pace appropriate? (Too slow / Just right / Too fast)
3. Which level was most valuable?
4. Which level was most challenging?
5. Quality of course materials (1-5)
6. Trainer effectiveness (1-5)
7. What did you like most?
8. What should we improve?
9. Would you recommend this workshop? (Yes/No/Maybe)
10. Additional comments

### Follow-up (1-2 weeks after)

**Send follow-up email**:
```
Subject: Workshop Follow-up - Next Steps

Hi [Student Name],

It's been a week since the workshop. I hope you're applying your new skills!

NEXT STEPS:

1. Keep Your Branch Updated:
   - Continue practicing on your student branch
   - Try building something new with Kafka

2. Join the Community:
   - Confluent Community Slack: [link]
   - Kafka mailing lists: [link]

3. Additional Resources:
   - Confluent Documentation: https://docs.confluent.io
   - Kafka: The Definitive Guide (book)
   - Confluent Developer courses: https://developer.confluent.io

4. Stay in Touch:
   - Questions? Email me anytime
   - LinkedIn: [your profile]

Congratulations again on your certification!

Best regards,
[Trainer Name]
```

### Repository Cleanup (Optional)

**After 3-6 months**:
```bash
# Archive old student branches
git tag archive/student/<username> student/<username>
git push origin archive/student/<username>

# Delete remote student branches (ONLY if students have been notified)
git push origin --delete student/<username>

# Students can still access via tag:
git checkout archive/student/<username>
```

---

## 📎 Appendix: Scripts & Automation

### Essential Coach Scripts

#### **1. Check All Student Activity**

```bash
#!/bin/bash
# scripts/coach-check-all-students.sh

echo "=== Student Activity Report ==="
echo "Generated: $(date)"
echo ""

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')

  echo "--- $username ---"
  echo "Branch: $branch"
  echo "Last commit:"
  git log --oneline --max-count=1 origin/$branch
  echo "Last activity:"
  git log --format="%ar" --max-count=1 origin/$branch
  echo ""
done
```

#### **2. Verify All Trackers**

```bash
#!/bin/bash
# scripts/verify-all-trackers.sh

echo "=== Progress Tracker Verification ==="
echo ""

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')
  tracker="docs/workshop/PROGRESS_TRACKER_${username}.md"

  git show "origin/$branch:$tracker" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✅ $username"
  else
    echo "❌ $username (NO TRACKER)"
  fi
done
```

#### **3. Generate Workshop Report**

```bash
#!/bin/bash
# scripts/generate-workshop-report.sh

echo "# Workshop Summary Report"
echo "**Generated**: $(date)"
echo ""

echo "## Student Statistics"
total=$(git branch -r | grep student/ | wc -l)
echo "**Total Students**: $total"
echo ""

echo "## Student Progress"
echo ""
echo "| Student | Last Activity | Commits | Status |"
echo "|---------|---------------|---------|--------|"

for branch in $(git branch -r | grep student/ | sed 's/origin\///'); do
  username=$(echo $branch | sed 's/student\///')
  last_activity=$(git log --format="%ar" --max-count=1 origin/$branch)
  commit_count=$(git rev-list --count origin/$branch)

  echo "| $username | $last_activity | $commit_count | 🔄 |"
done

echo ""
echo "## Badge Completion"
echo "(Manual verification required)"
echo ""
```

#### **4. Bulk PR Review Helper**

```bash
#!/bin/bash
# scripts/bulk-pr-check.sh

echo "=== Pending Workshop PRs ==="
echo ""

for pr in $(gh pr list --label "workshop" --state open --json number --jq '.[].number'); do
  echo "=== PR #$pr ==="
  gh pr view $pr --json number,title,author,createdAt,additions,deletions

  # Checkout and validate
  gh pr checkout $pr
  echo "Running validation..."
  ./scripts/workshop-check.sh final

  echo ""
  read -p "Review this PR now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh pr review $pr
  fi
  echo ""
done

git checkout main
```

### Automation Tips

#### **GitHub Labels for Organization**

Create labels for workshop management:
```bash
gh label create "workshop" --description "Workshop-related PR" --color "0E8A16"
gh label create "level-101" --description "Level 101 certification" --color "1D76DB"
gh label create "level-201" --description "Level 201 certification" --color "0052CC"
gh label create "level-301" --description "Level 301 certification" --color "5319E7"
gh label create "level-401" --description "Level 401 certification" --color "B60205"
```

**Auto-label PRs from student branches**:
```bash
# .github/workflows/auto-label-workshop-pr.yml
name: Auto-label Workshop PRs
on:
  pull_request:
    types: [opened]

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - name: Label workshop PRs
        if: startsWith(github.head_ref, 'student/')
        uses: actions/labeler@v4
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          sync-labels: true
```

---

## 🎯 Tips for Effective Coaching

### Engagement Techniques

1. **Live Coding**:
   - Code alongside students
   - Make mistakes intentionally and debug together
   - Think out loud

2. **Pair Programming**:
   - Pair struggling students with advanced students
   - Rotate pairs for different blocks

3. **Gamification**:
   - Leaderboard for badges earned
   - "First to complete" recognition
   - Bonus challenges for fast finishers

4. **Interactive Demos**:
   - Ask students to predict outcomes
   - "What would happen if...?" scenarios
   - Live troubleshooting sessions

### Managing Different Skill Levels

**For Advanced Students**:
- Provide bonus challenges
- Ask them to help peers
- Deeper dives into architecture

**For Struggling Students**:
- More frequent check-ins
- Pair with advanced student
- Focus on core concepts, skip optional content

### Time Management

**If Running Behind**:
1. Skip optional exercises
2. Demo instead of hands-on for some blocks
3. Assign remaining blocks as homework
4. Extend workshop (if possible)

**If Running Ahead**:
1. Deeper Q&A sessions
2. Real-world case studies
3. Preview next level content
4. Open discussion on architecture

---

## 📞 Getting Help

**For Coaches**:
- Confluent Trainer Slack: #trainers-confluent-dev
- Escalate technical issues: [trainer-support@confluent.io]
- Share best practices: monthly trainer calls

---

**Version**: 1.0
**Last Updated**: 2026-02-11
**Author**: Claude (AI Coach Assistant)
