#!/usr/bin/env bash
# ==============================================================================
# diagnose.sh — Kafka application diagnostics & troubleshooting toolkit
#
# Usage:
#   ./scripts/diagnose.sh connectivity        — Test broker connectivity
#   ./scripts/diagnose.sh consumer-lag        — Check consumer group lag
#   ./scripts/diagnose.sh topic-inspect       — Inspect topic metadata
#   ./scripts/diagnose.sh kstreams-state      — Check KStreams app state
#   ./scripts/diagnose.sh schema-check        — Validate Schema Registry
#   ./scripts/diagnose.sh k8s-status          — K8s pod status & logs
#   ./scripts/diagnose.sh full                — Run all checks
#   ./scripts/diagnose.sh -local full         — Force local defaults (ignore .env)
# ==============================================================================
set -euo pipefail

USE_LOCAL=false
if [ "${1:-}" = "-local" ]; then
    USE_LOCAL=true
    shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

load_env_file() {
    local file="$1"
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ""|\#*) continue ;;
        esac
        if [[ "$line" == export\ * ]]; then
            line="${line#export }"
        fi
        if [[ "$line" == *"="* ]]; then
            local key="${line%%=*}"
            local val="${line#*=}"
            if [[ "$val" == \"*\" && "$val" == *\" ]]; then
                val="${val:1:${#val}-2}"
                val="${val//\\\"/\"}"
                val="${val//\\\\/\\}"
            elif [[ "$val" == \'*\' && "$val" == *\' ]]; then
                val="${val:1:${#val}-2}"
            fi
            export "$key=$val"
        fi
    done < "$file"
}

if [ "$USE_LOCAL" = false ] && [ -f "$ENV_FILE" ]; then
    load_env_file "$ENV_FILE"
fi

BOOTSTRAP="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
SR_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"
NAMESPACE="${K8S_NAMESPACE:-confluent-apps}"
CONSUMER_GROUP="${CONSUMER_GROUP:-payment-consumer-group}"
SEC_PROTOCOL="${KAFKA_SECURITY_PROTOCOL:-SASL_SSL}"
SASL_MECH="${KAFKA_SASL_MECHANISM:-PLAIN}"
SASL_JAAS="${KAFKA_SASL_JAAS_CONFIG:-}"
SR_USER_INFO="${SCHEMA_REGISTRY_USER_INFO:-}"

CLIENT_CONFIG=""
cleanup() {
    if [ -n "$CLIENT_CONFIG" ] && [ -f "$CLIENT_CONFIG" ]; then
        rm -f "$CLIENT_CONFIG"
    fi
}
trap cleanup EXIT

build_client_config() {
    if [ -z "$SASL_JAAS" ]; then
        return 1
    fi
    CLIENT_CONFIG="$(mktemp)"
    {
        echo "security.protocol=$SEC_PROTOCOL"
        echo "sasl.mechanism=$SASL_MECH"
        echo "sasl.jaas.config=$SASL_JAAS"
    } > "$CLIENT_CONFIG"
    return 0
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
header(){ echo -e "\n========================================"; echo "  $1"; echo "========================================"; }

# ---------- Connectivity ----------
check_connectivity() {
    header "Broker Connectivity"
    echo "  Target: $BOOTSTRAP"

    if command -v kafka-broker-api-versions &>/dev/null; then
        if build_client_config && kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP" --command-config "$CLIENT_CONFIG" 2>/dev/null | head -1 | grep -q "ApiVersion"; then
            pass "Broker reachable"
        elif kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP" --command-config /dev/null 2>/dev/null | head -1 | grep -q "ApiVersion"; then
            pass "Broker reachable"
        else
            fail "Cannot reach broker at $BOOTSTRAP"
        fi
    elif command -v kcat &>/dev/null; then
        if [ -n "$SASL_JAAS" ]; then
            if kcat -b "$BOOTSTRAP" -X security.protocol="$SEC_PROTOCOL" -X sasl.mechanism="$SASL_MECH" -X sasl.username="$KAFKA_API_KEY" -X sasl.password="$KAFKA_API_SECRET" -L -t __consumer_offsets 2>/dev/null | grep -q "broker"; then
                pass "Broker reachable (via kcat)"
            else
                fail "Cannot reach broker (kcat)"
            fi
        elif kcat -b "$BOOTSTRAP" -L -t __consumer_offsets 2>/dev/null | grep -q "broker"; then
            pass "Broker reachable (via kcat)"
        else
            fail "Cannot reach broker (kcat)"
        fi
    else
        warn "Neither kafka-broker-api-versions nor kcat found — install one for connectivity checks"
        echo "  Attempting basic TCP check..."
        HOST=$(echo "$BOOTSTRAP" | cut -d: -f1)
        PORT=$(echo "$BOOTSTRAP" | cut -d: -f2)
        if timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
            pass "TCP port $PORT reachable on $HOST"
        else
            fail "TCP port $PORT NOT reachable on $HOST"
        fi
    fi
}

# ---------- Consumer Lag ----------
check_consumer_lag() {
    header "Consumer Group Lag"
    echo "  Group: $CONSUMER_GROUP"

    if command -v kafka-consumer-groups &>/dev/null; then
        if build_client_config; then
            kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
                --command-config "$CLIENT_CONFIG" \
                --describe --group "$CONSUMER_GROUP" 2>/dev/null || fail "Could not describe group"
        else
            kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
                --describe --group "$CONSUMER_GROUP" 2>/dev/null || fail "Could not describe group"
        fi
    elif command -v confluent &>/dev/null; then
        confluent kafka consumer group lag describe "$CONSUMER_GROUP" 2>/dev/null || fail "Could not describe group"
    else
        warn "No Kafka CLI tools found. Install kafka-consumer-groups or confluent CLI."
    fi
}

# ---------- Topic Inspect ----------
check_topics() {
    header "Topic Inspection"

    TOPICS=("payments" "fraud-alerts" "approved-payments")
    for topic in "${TOPICS[@]}"; do
        echo ""
        echo "  --- $topic ---"
        if command -v kafka-topics &>/dev/null; then
            if build_client_config; then
                kafka-topics --bootstrap-server "$BOOTSTRAP" --command-config "$CLIENT_CONFIG" --describe --topic "$topic" 2>/dev/null \
                    || warn "Topic '$topic' not found or inaccessible"
            else
                kafka-topics --bootstrap-server "$BOOTSTRAP" --describe --topic "$topic" 2>/dev/null \
                    || warn "Topic '$topic' not found or inaccessible"
            fi
        elif command -v kcat &>/dev/null; then
            if [ -n "$SASL_JAAS" ]; then
                kcat -b "$BOOTSTRAP" -X security.protocol="$SEC_PROTOCOL" -X sasl.mechanism="$SASL_MECH" -X sasl.username="$KAFKA_API_KEY" -X sasl.password="$KAFKA_API_SECRET" -L -t "$topic" 2>/dev/null | head -20 \
                    || warn "Topic '$topic' not found"
            else
                kcat -b "$BOOTSTRAP" -L -t "$topic" 2>/dev/null | head -20 \
                    || warn "Topic '$topic' not found"
            fi
        elif command -v confluent &>/dev/null; then
            confluent kafka topic describe "$topic" 2>/dev/null \
                || warn "Topic '$topic' not found"
        fi
    done
}

# ---------- KStreams State ----------
check_kstreams_state() {
    header "Kafka Streams Application State"

    KSTREAMS_GROUP="fraud-detection-app"
    if command -v kafka-consumer-groups &>/dev/null; then
        echo "  Checking consumer group for KStreams app: $KSTREAMS_GROUP"
        if build_client_config; then
            kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
                --command-config "$CLIENT_CONFIG" \
                --describe --group "$KSTREAMS_GROUP" 2>/dev/null || warn "Group not found"
        else
            kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
                --describe --group "$KSTREAMS_GROUP" 2>/dev/null || warn "Group not found"
        fi
    fi

    echo ""
    echo "  Checking internal topics (changelog, repartition):"
    if command -v kafka-topics &>/dev/null; then
        if build_client_config; then
            kafka-topics --bootstrap-server "$BOOTSTRAP" --command-config "$CLIENT_CONFIG" --list 2>/dev/null \
                | grep -E "fraud-detection" || warn "No internal KStreams topics found"
        else
            kafka-topics --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null \
                | grep -E "fraud-detection" || warn "No internal KStreams topics found"
        fi
    fi
}

# ---------- Schema Registry ----------
check_schema_registry() {
    header "Schema Registry"
    echo "  URL: $SR_URL"

    if command -v curl &>/dev/null; then
        if [ -n "$SR_USER_INFO" ]; then
            HTTP_CODE=$(curl -s -u "$SR_USER_INFO" -o /dev/null -w "%{http_code}" "$SR_URL/subjects" 2>/dev/null || echo "000")
        else
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SR_URL/subjects" 2>/dev/null || echo "000")
        fi
        if [ "$HTTP_CODE" = "200" ]; then
            pass "Schema Registry reachable (HTTP $HTTP_CODE)"
            echo "  Subjects:"
            if [ -n "$SR_USER_INFO" ]; then
                curl -s -u "$SR_USER_INFO" "$SR_URL/subjects" 2>/dev/null | tr ',' '\n' | sed 's/[]"[]//g' | sed 's/^/    /'
            else
                curl -s "$SR_URL/subjects" 2>/dev/null | tr ',' '\n' | sed 's/[]"[]//g' | sed 's/^/    /'
            fi
        else
            fail "Schema Registry returned HTTP $HTTP_CODE"
        fi
    else
        warn "curl not found"
    fi
}

# ---------- K8s Status ----------
check_k8s_status() {
    header "Kubernetes Pod Status"
    echo "  Namespace: $NAMESPACE"

    if command -v kubectl &>/dev/null; then
        echo ""
        echo "  --- Pods ---"
        kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || warn "Cannot list pods"

        echo ""
        echo "  --- Recent Events ---"
        kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -15 \
            || warn "Cannot list events"

        echo ""
        echo "  --- Pod Logs (last 20 lines per pod) ---"
        for pod in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
            echo ""
            echo "  >>> $pod"
            kubectl logs "$pod" -n "$NAMESPACE" --tail=20 2>/dev/null || warn "Cannot fetch logs for $pod"
        done
    else
        warn "kubectl not found"
    fi
}

# ---------- Main ----------
case "${1:-full}" in
    connectivity)     check_connectivity ;;
    consumer-lag)     check_consumer_lag ;;
    topic-inspect)    check_topics ;;
    kstreams-state)   check_kstreams_state ;;
    schema-check)     check_schema_registry ;;
    k8s-status)       check_k8s_status ;;
    full)
        check_connectivity
        check_consumer_lag
        check_topics
        check_kstreams_state
        check_schema_registry
        check_k8s_status
        ;;
    *)
        echo "Usage: $0 [connectivity|consumer-lag|topic-inspect|kstreams-state|schema-check|k8s-status|full]"
        exit 1
        ;;
esac
