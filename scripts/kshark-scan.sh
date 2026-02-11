#!/usr/bin/env bash
# ==============================================================================
# kshark-scan.sh — Run kshark against the current Kubernetes context
#
# Usage:
#   ./scripts/kshark-scan.sh [args...]
#   KSHARK_NAMESPACE=confluent-apps ./scripts/kshark-scan.sh
#   KSHARK_ARGS="tap --namespace confluent-apps" ./scripts/kshark-scan.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tools"
KSHARK_BIN="$TOOLS_DIR/kshark"
PROPS_FILE="${KSHARK_PROPS:-$ROOT_DIR/client.properties}"
TOPICS_DEFAULT="payments,fraud-alerts,approved-payments"
LICENSE_PATH="${KSHARK_LICENSE:-}"
AI_CONFIG_PATH="${KSHARK_AI_CONFIG:-$ROOT_DIR/tools/ai_config.json}"
#KSHARK_TIMEOUT="${KSHARK_TIMEOUT:-120s}"
KSHARK_TIMEOUT="120s"
KSHARK_DIAG="${KSHARK_DIAG:-false}"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
KSHARK_PRODUCE_TEST="${KSHARK_PRODUCE_TEST:-false}"
KSHARK_PRODUCE_TOPIC="${KSHARK_PRODUCE_TOPIC:-payments}"

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

if [ -f "$ENV_FILE" ]; then
    load_env_file "$ENV_FILE"
fi

if [ -z "${ENV_NAME:-}" ] && [ -f "$ENV_FILE" ]; then
    ENV_NAME="$(grep -E '^ENV_NAME=' "$ENV_FILE" | head -n 1 | cut -d= -f2- | sed 's/^\"//;s/\"$//')"
fi

ENV_NAME_VALUE="${ENV_NAME:-unknown-env}"
TS="$(date -u +%Y%m%d_%H%M%SZ)"
REPORTS_BASE="$TOOLS_DIR/kshark-reports"
RUN_DIR="$REPORTS_BASE/${ENV_NAME_VALUE}_${TS}"

acl_preflight() {
    if ! command -v confluent >/dev/null 2>&1; then
        echo "[WARN] confluent CLI not found; skipping ACL preflight."
        return 0
    fi
    local env_arg=""
    local cluster_arg=""
    if [ -n "${ENV_ID:-}" ]; then
        env_arg="--environment ${ENV_ID}"
    fi
    if [ -n "${CLUSTER_ID:-}" ]; then
        cluster_arg="--cluster ${CLUSTER_ID}"
    fi

    if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ]; then
        local principal="User:${KAFKA_SERVICE_ACCOUNT_ID}"
        echo "==> ACL preflight for service account: ${KAFKA_SERVICE_ACCOUNT_ID} (env=${ENV_ID:-current}, cluster=${CLUSTER_ID:-current})"
        if ! confluent kafka acl list $env_arg $cluster_arg --principal "$principal" >/dev/null 2>&1; then
            echo "[WARN] Could not read ACLs for principal $principal (check permissions/context)."
            return 0
        fi
    elif [ -n "${KAFKA_API_KEY:-}" ]; then
        echo "==> ACL preflight for key: ${KAFKA_API_KEY} (env=${ENV_ID:-current}, cluster=${CLUSTER_ID:-current})"
        if ! confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_API_KEY}" >/dev/null 2>&1; then
            echo "[WARN] Could not read ACLs for principal User:${KAFKA_API_KEY} (check permissions/context)."
            return 0
        fi
    else
        echo "[WARN] No service account or API key set; skipping ACL preflight."
        return 0
    fi

    local topics=("payments" "fraud-alerts" "approved-payments")
    local missing=0
    local use_jq=false
    if command -v jq >/dev/null 2>&1; then
        use_jq=true
    fi
    local acl_json=""
    if [ "$use_jq" = true ]; then
        if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ]; then
            acl_json="$(confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_SERVICE_ACCOUNT_ID}" -o json 2>/dev/null || true)"
        else
            acl_json="$(confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_API_KEY}" -o json 2>/dev/null || true)"
        fi
        if [ -z "$acl_json" ] || [ "$acl_json" = "[]" ]; then
            echo "[WARN] Could not read ACLs (empty response); skipping ACL preflight."
            return 0
        fi
    fi
    for t in "${topics[@]}"; do
        if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ]; then
            if [ "$use_jq" = true ]; then
                if echo "$acl_json" | jq -e --arg t "$t" '
                    (map(select(.resource_type=="TOPIC" and .resource_name==$t))
                     | map(.operation|ascii_upcase)
                     | unique) as $ops
                    | ($ops|index("READ") != null)
                      and ($ops|index("WRITE") != null)
                      and ($ops|index("DESCRIBE") != null)
                  ' >/dev/null; then
                    echo "  [OK] Topic ACLs present for $t"
                else
                    echo "  [WARN] Missing topic ACLs for $t (need WRITE/DESCRIBE/READ)"
                    missing=1
                fi
            elif confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_SERVICE_ACCOUNT_ID}" --topic "$t" 2>/dev/null | grep -Eiq 'WRITE|DESCRIBE|READ'; then
                echo "  [OK] Topic ACLs present for $t"
            else
                echo "  [WARN] Missing topic ACLs for $t (need WRITE/DESCRIBE/READ)"
                missing=1
            fi
        elif [ "$use_jq" = true ]; then
            if echo "$acl_json" | jq -e --arg t "$t" '
                (map(select(.resource_type=="TOPIC" and .resource_name==$t))
                 | map(.operation|ascii_upcase)
                 | unique) as $ops
                | ($ops|index("READ") != null)
                  and ($ops|index("WRITE") != null)
                  and ($ops|index("DESCRIBE") != null)
              ' >/dev/null; then
                echo "  [OK] Topic ACLs present for $t"
            else
                echo "  [WARN] Missing topic ACLs for $t (need WRITE/DESCRIBE/READ)"
                missing=1
            fi
        elif confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_API_KEY}" --topic "$t" 2>/dev/null | grep -Eiq 'WRITE|DESCRIBE|READ'; then
            echo "  [OK] Topic ACLs present for $t"
        else
            echo "  [WARN] Missing topic ACLs for $t (need WRITE/DESCRIBE/READ)"
            missing=1
        fi
    done
    local group_name="${CONSUMER_GROUP:-payment-consumer-group}"
    if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ]; then
        if [ "$use_jq" = true ]; then
            if [ "${ACL_PREFLIGHT_DEBUG:-false}" = "true" ]; then
                echo "  [DEBUG] Group ACL ops: $(echo "$acl_json" | jq -r --arg g "$group_name" 'map(select(.resource_type=="GROUP" and (.resource_name=="*" or .resource_name==$g))) | map(.operation|ascii_upcase) | unique | join(",")')"
            fi
            if echo "$acl_json" | jq -e --arg g "$group_name" '
                (map(select(.resource_type=="GROUP" and (.resource_name=="*" or .resource_name==$g)))
                 | map(.operation|ascii_upcase)
                 | unique) as $ops
                | ($ops|index("READ") != null)
                  and ($ops|index("DESCRIBE") != null)
              ' >/dev/null; then
                echo "  [OK] Group ACLs present (READ/DESCRIBE)"
            else
                echo "  [WARN] Missing group ACLs (need READ/DESCRIBE on group)"
                missing=1
            fi
        elif confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_SERVICE_ACCOUNT_ID}" --group '*' 2>/dev/null | grep -Eiq 'READ|DESCRIBE' \
          || confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_SERVICE_ACCOUNT_ID}" --group "$group_name" 2>/dev/null | grep -Eiq 'READ|DESCRIBE'; then
            echo "  [OK] Group ACLs present (READ/DESCRIBE)"
        else
            echo "  [WARN] Missing group ACLs (need READ/DESCRIBE on group)"
            missing=1
        fi
    elif [ "$use_jq" = true ]; then
        if echo "$acl_json" | jq -e --arg g "$group_name" '
            (map(select(.resource_type=="GROUP" and (.resource_name=="*" or .resource_name==$g)))
             | map(.operation|ascii_upcase)
             | unique) as $ops
            | ($ops|index("READ") != null)
              and ($ops|index("DESCRIBE") != null)
          ' >/dev/null; then
            echo "  [OK] Group ACLs present (READ/DESCRIBE)"
        else
            echo "  [WARN] Missing group ACLs (need READ/DESCRIBE on group)"
            missing=1
        fi
    elif confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_API_KEY}" --group '*' 2>/dev/null | grep -Eiq 'READ|DESCRIBE' \
      || confluent kafka acl list $env_arg $cluster_arg --principal "User:${KAFKA_API_KEY}" --group "$group_name" 2>/dev/null | grep -Eiq 'READ|DESCRIBE'; then
        echo "  [OK] Group ACLs present (READ/DESCRIBE)"
    else
        echo "  [WARN] Missing group ACLs (need READ/DESCRIBE on group)"
        missing=1
    fi
    if [ "$missing" -eq 1 ]; then
        echo "[WARN] ACLs appear incomplete. Produce probes may time out."
    fi
}

producer_test() {
    if [ "$KSHARK_PRODUCE_TEST" != "true" ]; then
        return 0
    fi
    if ! command -v kcat >/dev/null 2>&1; then
        echo "[WARN] kcat not found; skipping producer test."
        return 0
    fi
    if [ ! -f "$PROPS_FILE" ]; then
        echo "[WARN] client.properties not found; skipping producer test."
        return 0
    fi
    local kcat_props
    kcat_props="$(mktemp)"
    # kcat/librdkafka does not support sasl.jaas.config or Schema Registry properties.
    grep -Ev '^[[:space:]]*(sasl\.jaas\.config|schema\.registry\.|basic\.auth\.)' "$PROPS_FILE" > "$kcat_props"
    if ! grep -q '^[[:space:]]*sasl\.username=' "$kcat_props"; then
        local jaas_line user pass
        jaas_line="$(grep -E '^[[:space:]]*sasl\.jaas\.config=' "$PROPS_FILE" | head -n 1 || true)"
        if [ -n "$jaas_line" ]; then
            user="$(printf '%s' "$jaas_line" | sed -n "s/.*username='\\([^']*\\)'.*/\\1/p")"
            pass="$(printf '%s' "$jaas_line" | sed -n "s/.*password='\\([^']*\\)'.*/\\1/p")"
        else
            user="${KAFKA_SERVICE_ACCOUNT_KEY:-${KAFKA_API_KEY:-}}"
            pass="${KAFKA_SERVICE_ACCOUNT_SECRET:-${KAFKA_API_SECRET:-}}"
        fi
        if [ -n "${user:-}" ] && [ -n "${pass:-}" ]; then
            echo "sasl.username=${user}" >> "$kcat_props"
            echo "sasl.password=${pass}" >> "$kcat_props"
        fi
    fi
    if ! grep -q '^[[:space:]]*security\.protocol=' "$kcat_props"; then
        echo "security.protocol=SASL_SSL" >> "$kcat_props"
    fi
    if ! grep -q '^[[:space:]]*sasl\.mechanism=' "$kcat_props"; then
        echo "sasl.mechanism=PLAIN" >> "$kcat_props"
    fi
    local msg="kshark-cli-probe $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "==> kcat producer test: topic=${KSHARK_PRODUCE_TOPIC}"
    local kcat_err_file kcat_rc
    kcat_err_file="$(mktemp)"
    if printf '%s\n' "$msg" | kcat -P -t "$KSHARK_PRODUCE_TOPIC" -F "$kcat_props" 2>"$kcat_err_file" >/dev/null; then
        if [ -s "$kcat_err_file" ]; then
            echo "  [OK] Produced one message via kcat."
            echo "  [WARN] kcat warnings: $(tr '\n' ' ' < "$kcat_err_file")"
        else
            echo "  [OK] Produced one message via kcat."
        fi
        rm -f "$kcat_err_file" "$kcat_props"
        return 0
    fi
    kcat_rc=$?
    echo "  [FAIL] kcat producer failed (exit=$kcat_rc)."
    if [ -s "$kcat_err_file" ]; then
        echo "  [FAIL] kcat error: $(tr '\n' ' ' < "$kcat_err_file")"
    fi
    rm -f "$kcat_err_file" "$kcat_props"
}

if [ ! -x "$KSHARK_BIN" ]; then
    echo "[ERROR] kshark not found. Run: ./scripts/kshark-init.sh" >&2
    exit 1
fi

if [ -x "$ROOT_DIR/scripts/create-client-properties.sh" ]; then
    "$ROOT_DIR/scripts/create-client-properties.sh" "$PROPS_FILE"
else
    if [ ! -f "$PROPS_FILE" ]; then
        echo "[ERROR] client properties not found at $PROPS_FILE" >&2
        exit 1
    fi
fi

if [ "$#" -gt 0 ]; then
    exec "$KSHARK_BIN" "$@"
fi

if [ -n "${KSHARK_ARGS:-}" ]; then
    exec "$KSHARK_BIN" $KSHARK_ARGS
fi

acl_preflight
producer_test

mkdir -p "$RUN_DIR/reports"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [ -f "$AI_CONFIG_PATH" ]; then
    cp "$AI_CONFIG_PATH" "$TMP_DIR/ai_config.json"
fi

JSON_OUT="$RUN_DIR/reports/kshark.json"
echo "==> kshark topic scan: $TOPICS_DEFAULT"
(cd "$TMP_DIR" && "$KSHARK_BIN" -props "$PROPS_FILE" -topic "$TOPICS_DEFAULT" --analyze -json "$JSON_OUT" -timeout "$KSHARK_TIMEOUT" -diag="$KSHARK_DIAG" -no-ai -y) || true

if [ -d "$TMP_DIR/reports" ]; then
    mv "$TMP_DIR/reports/"* "$RUN_DIR/reports/" 2>/dev/null || true
fi

echo "Reports & Prompts: $RUN_DIR/reports"
