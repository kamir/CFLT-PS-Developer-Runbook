#!/usr/bin/env bash
# ==============================================================================
# workshop-check.sh — Validates workshop block completion (Sporen)
#
# Usage:
#   ./scripts/workshop-check.sh block1    # Bronzener Sporn
#   ./scripts/workshop-check.sh block2    # Silberner Sporn
#   ./scripts/workshop-check.sh block3    # Goldener Sporn
#   ./scripts/workshop-check.sh block4    # Eiserner Sporn
#   ./scripts/workshop-check.sh block5    # Stahlerner Sporn
#   ./scripts/workshop-check.sh block6    # Diamantener Sporn
#   ./scripts/workshop-check.sh final     # Meister-Sporn (all blocks)
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass()  { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
header(){ echo -e "\n${BOLD}========================================"; echo "  $1"; echo -e "========================================${NC}"; }
sporn() { echo -e "\n  ${CYAN}${BOLD}>>> $1 <<<${NC}\n"; }

# ---------- Block 1: Bronzener Sporn ----------
check_block1() {
    header "Block 1 — Bronzener Sporn"

    # Docker containers running
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "broker"; then
        pass "Docker container 'broker' is running"
    else
        fail "Docker container 'broker' is NOT running"
    fi

    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "schema-registry"; then
        pass "Docker container 'schema-registry' is running"
    else
        fail "Docker container 'schema-registry' is NOT running"
    fi

    # Topics exist
    TOPICS=$(docker exec broker kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null || echo "")
    for topic in payments fraud-alerts approved-payments; do
        if echo "$TOPICS" | grep -q "^${topic}$"; then
            pass "Topic '$topic' exists"
        else
            fail "Topic '$topic' does NOT exist"
        fi
    done

    # Messages in payments topic
    MSG_COUNT=$(docker exec broker kafka-run-class kafka.tools.GetOffsetShell \
        --broker-list localhost:9092 --topic payments --time -1 2>/dev/null \
        | awk -F: '{sum += $3} END {print sum}' || echo "0")
    if [ "${MSG_COUNT:-0}" -gt 0 ]; then
        pass "Messages found in 'payments' topic (count: $MSG_COUNT)"
    else
        fail "No messages found in 'payments' topic — did you run the producer?"
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "BRONZENER SPORN EARNED!"
    fi
}

# ---------- Block 2: Silberner Sporn ----------
check_block2() {
    header "Block 2 — Silberner Sporn"

    # Project builds
    if [ -f producer-consumer-app/target/producer-consumer-app-1.0.0-SNAPSHOT.jar ]; then
        pass "Producer-consumer JAR exists"
    else
        fail "Producer-consumer JAR not found — run 'mvn package'"
    fi

    # Unit tests pass
    if mvn test -pl producer-consumer-app -q 2>/dev/null; then
        pass "Producer-consumer unit tests pass"
    else
        fail "Producer-consumer unit tests FAILED"
    fi

    # Check PCI-DSS: no full card numbers in source
    if grep -r "\\b[0-9]\\{13,19\\}\\b" producer-consumer-app/src/main/java/ 2>/dev/null | grep -v "masked" | grep -v "test" | grep -qv "sequence"; then
        fail "Possible unmasked card number found in source code!"
    else
        pass "No unmasked card numbers in source (PCI-DSS compliant)"
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "SILBERNER SPORN EARNED!"
    fi
}

# ---------- Block 3: Goldener Sporn ----------
check_block3() {
    header "Block 3 — Goldener Sporn"

    # KStreams JAR exists
    if [ -f kstreams-app/target/kstreams-app-1.0.0-SNAPSHOT.jar ]; then
        pass "KStreams JAR exists"
    else
        fail "KStreams JAR not found — run 'mvn package'"
    fi

    # KStreams tests pass
    if mvn test -pl kstreams-app -q 2>/dev/null; then
        pass "KStreams topology tests pass"
    else
        fail "KStreams topology tests FAILED"
    fi

    # Check that the topology source contains expected methods
    if grep -q "computeRiskScore" kstreams-app/src/main/java/io/confluent/ps/kstreams/topology/FraudDetectionTopology.java 2>/dev/null; then
        pass "FraudDetectionTopology contains risk scoring logic"
    else
        fail "FraudDetectionTopology missing computeRiskScore method"
    fi

    # Check for fraud-alerts output in the topology
    if grep -q "fraud-alerts" kstreams-app/src/main/java/io/confluent/ps/kstreams/topology/FraudDetectionTopology.java 2>/dev/null; then
        pass "Topology routes flagged transactions to 'fraud-alerts'"
    else
        fail "Topology does not reference 'fraud-alerts' topic"
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "GOLDENER SPORN EARNED!"
    fi
}

# ---------- Block 4: Eiserner Sporn ----------
check_block4() {
    header "Block 4 — Eiserner Sporn"

    # Config files exist for all environments
    for env in dev qa prod; do
        if [ -f "producer-consumer-app/src/main/resources/application-${env}.properties" ]; then
            pass "Config file application-${env}.properties exists"
        else
            fail "Config file application-${env}.properties missing"
        fi
    done

    # Check that git has branches
    BRANCH_COUNT=$(git branch --list 2>/dev/null | wc -l)
    if [ "$BRANCH_COUNT" -ge 1 ]; then
        pass "Git repository has branches ($BRANCH_COUNT found)"
    else
        fail "No git branches found"
    fi

    # Check for recent commits
    COMMIT_COUNT=$(git log --oneline 2>/dev/null | wc -l)
    if [ "$COMMIT_COUNT" -ge 1 ]; then
        pass "Git repository has commits ($COMMIT_COUNT found)"
    else
        fail "No git commits found"
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "EISERNER SPORN EARNED!"
    fi
}

# ---------- Block 5: Stahlerner Sporn ----------
check_block5() {
    header "Block 5 — Stahlerner Sporn"

    # Dockerfiles exist
    for df in docker/Dockerfile.producer-consumer docker/Dockerfile.kstreams; do
        if [ -f "$df" ]; then
            pass "Dockerfile exists: $df"
        else
            fail "Dockerfile missing: $df"
        fi
    done

    # Check Dockerfiles for security: non-root user
    for df in docker/Dockerfile.producer-consumer docker/Dockerfile.kstreams; do
        if grep -q "USER" "$df" 2>/dev/null; then
            pass "$df runs as non-root user (PCI-DSS)"
        else
            fail "$df does NOT specify a non-root USER"
        fi
    done

    # K8s manifests exist
    for f in k8s/base/namespace.yaml k8s/base/networkpolicy.yaml k8s/base/producer-deployment.yaml k8s/base/kstreams-deployment.yaml; do
        if [ -f "$f" ]; then
            pass "K8s manifest exists: $f"
        else
            fail "K8s manifest missing: $f"
        fi
    done

    # Kustomize overlays exist
    for env in dev qa prod; do
        if [ -f "k8s/overlays/${env}/kustomization.yaml" ]; then
            pass "Kustomize overlay exists: ${env}"
        else
            fail "Kustomize overlay missing: ${env}"
        fi
    done

    # CI/CD pipelines exist
    for wf in .github/workflows/ci.yaml .github/workflows/cd-gitops.yaml; do
        if [ -f "$wf" ]; then
            pass "CI/CD pipeline exists: $wf"
        else
            fail "CI/CD pipeline missing: $wf"
        fi
    done

    # Docker images built (optional — check if they exist)
    if docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q "payment-app\|producer-consumer"; then
        pass "Docker image 'payment-app' found locally"
    else
        warn "Docker image 'payment-app' not found — build with: docker build -f docker/Dockerfile.producer-consumer -t payment-app:workshop ."
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "STAHLERNER SPORN EARNED!"
    fi
}

# ---------- Block 6: Diamantener Sporn ----------
check_block6() {
    header "Block 6 — Diamantener Sporn"

    # Diagnostics script exists and is executable
    if [ -x scripts/diagnose.sh ]; then
        pass "Diagnostics script is executable"
    else
        fail "Diagnostics script missing or not executable"
    fi

    # Broker is reachable (should be running again after scenario A)
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "broker"; then
        pass "Broker is running (Scenario A resolved)"
    else
        fail "Broker is NOT running — did you fix Scenario A?"
    fi

    # Schema Registry is reachable
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "schema-registry"; then
        pass "Schema Registry is running"
    else
        fail "Schema Registry is NOT running"
    fi

    # Check that diagnose.sh runs without errors
    if ./scripts/diagnose.sh connectivity 2>/dev/null | grep -q "PASS\|reachable"; then
        pass "Connectivity check passes"
    else
        warn "Connectivity check did not pass — broker may not be ready"
    fi

    if [ $FAIL_COUNT -eq 0 ]; then
        sporn "DIAMANTENER SPORN EARNED!"
    fi
}

# ---------- Final: Meister-Sporn ----------
check_final() {
    check_block1
    check_block2
    check_block3
    check_block4
    check_block5
    check_block6

    echo ""
    header "Final Results"
    echo -e "  Passed: ${GREEN}${PASS_COUNT}${NC}"
    echo -e "  Failed: ${RED}${FAIL_COUNT}${NC}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${BOLD}${CYAN}"
        echo "  =================================================="
        echo "    MEISTER-SPORN EARNED!"
        echo "    Congratulations — you are now a"
        echo "    Confluent Cloud Java Developer!"
        echo "  =================================================="
        echo -e "${NC}"
    else
        echo -e "  ${YELLOW}Not all checks passed. Fix the issues and try again.${NC}"
    fi
}

# ---------- Main ----------
case "${1:-}" in
    block1) check_block1 ;;
    block2) check_block2 ;;
    block3) check_block3 ;;
    block4) check_block4 ;;
    block5) check_block5 ;;
    block6) check_block6 ;;
    final)  check_final ;;
    *)
        echo "Usage: $0 [block1|block2|block3|block4|block5|block6|final]"
        echo ""
        echo "  block1  — Bronzener Sporn  (Local Dev Environment)"
        echo "  block2  — Silberner Sporn  (Producer/Consumer & PCI-DSS)"
        echo "  block3  — Goldener Sporn   (Kafka Streams)"
        echo "  block4  — Eiserner Sporn   (Configuration & Git-Flow)"
        echo "  block5  — Stahlerner Sporn (Docker, K8s & GitOps)"
        echo "  block6  — Diamantener Sporn(Troubleshooting)"
        echo "  final   — Meister-Sporn    (All blocks)"
        exit 1
        ;;
esac
