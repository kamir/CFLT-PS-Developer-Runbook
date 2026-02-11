#!/usr/bin/env bash
# ==============================================================================
# kshark-diag-ccloud.sh — Diagnose Confluent Cloud resources for kshark
#
# Usage:
#   ./scripts/kshark-diag-ccloud.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
PROPS_FILE="${KSHARK_PROPS:-$ROOT_DIR/client.properties}"

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

mask_value() {
    local v="$1"
    local len=${#v}
    if [ "$len" -le 8 ]; then
        echo "****"
        return
    fi
    echo "${v:0:4}****${v:len-4:4}"
}

echo "==> kshark debug summary"
echo "  ENV_NAME       : ${ENV_NAME:-<not set>}"
echo "  ENV_ID         : ${ENV_ID:-<not set>}"
echo "  CLUSTER_ID     : ${CLUSTER_ID:-<not set>}"
echo "  CLUSTER_CLOUD  : ${CLUSTER_CLOUD:-<not set>}"
echo "  CLUSTER_REGION : ${CLUSTER_REGION:-<not set>}"
echo "  SA_ID          : ${KAFKA_SERVICE_ACCOUNT_ID:-<not set>}"
echo "  SR_SA_ID       : ${SCHEMA_REGISTRY_SERVICE_ACCOUNT_ID:-<not set>}"
echo "  client.properties: $PROPS_FILE"

if [ ! -f "$PROPS_FILE" ]; then
    if [ -x "$ROOT_DIR/scripts/create-client-properties.sh" ]; then
        echo "  [INFO] client.properties missing; generating from .env"
        "$ROOT_DIR/scripts/create-client-properties.sh" "$PROPS_FILE"
    fi
fi

if [ ! -f "$PROPS_FILE" ]; then
    echo "[ERROR] client.properties not found at $PROPS_FILE" >&2
    exit 1
fi

KSHARK_KEY="$(grep -E '^[[:space:]]*sasl\.username=' "$PROPS_FILE" | head -n 1 | cut -d= -f2- | tr -d '[:space:]')"
if [ -z "$KSHARK_KEY" ]; then
    echo "[ERROR] sasl.username not found in client.properties" >&2
    exit 1
fi

echo "  kshark API key : ${KSHARK_KEY}"

echo ""
echo "==> Endpoints (from .env)"
echo "  Kafka bootstrap : ${KAFKA_BOOTSTRAP_SERVERS:-<not set>}"
echo "  Schema Registry : ${SCHEMA_REGISTRY_URL:-<not set>}"

echo ""
echo "==> client.properties (sanitized)"
props_bootstrap="$(grep -E '^[[:space:]]*bootstrap\.servers=' "$PROPS_FILE" | head -n 1 | cut -d= -f2-)"
props_protocol="$(grep -E '^[[:space:]]*security\.protocol=' "$PROPS_FILE" | head -n 1 | cut -d= -f2-)"
props_mech="$(grep -E '^[[:space:]]*sasl\.mechanism=' "$PROPS_FILE" | head -n 1 | cut -d= -f2-)"
props_user="$(grep -E '^[[:space:]]*sasl\.username=' "$PROPS_FILE" | head -n 1 | cut -d= -f2-)"
props_sr="$(grep -E '^[[:space:]]*schema\.registry\.url=' "$PROPS_FILE" | head -n 1 | cut -d= -f2-)"
echo "  bootstrap.servers : ${props_bootstrap:-<not set>}"
echo "  security.protocol : ${props_protocol:-<not set>}"
echo "  sasl.mechanism    : ${props_mech:-<not set>}"
if [ -n "${props_user:-}" ]; then
    echo "  sasl.username     : $(mask_value "$props_user")"
else
    echo "  sasl.username     : <not set>"
fi
echo "  schema.registry.url: ${props_sr:-<not set>}"

if command -v confluent >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    echo ""
    echo "==> Environment (Confluent Cloud)"
    if [ -n "${ENV_ID:-}" ]; then
        env_json="$(confluent environment describe "$ENV_ID" -o json 2>/dev/null || true)"
        if [ -n "$env_json" ]; then
            echo "$env_json" | jq -r '"  name             : \(.name // "<unknown>")\n  id               : \(.id // "<unknown>")\n  stream_governance: \(.stream_governance_package // "<unknown>")"'
        else
            echo "  [WARN] Could not describe environment."
        fi
    else
        echo "  [SKIP] ENV_ID not set"
    fi

    echo ""
    echo "==> Cluster (Confluent Cloud)"
    if [ -n "${CLUSTER_ID:-}" ]; then
        cluster_json="$(confluent kafka cluster describe "$CLUSTER_ID" -o json 2>/dev/null || true)"
        if [ -n "$cluster_json" ]; then
            echo "$cluster_json" | jq -r '"  name        : \(.name // "<unknown>")\n  id          : \(.id // "<unknown>")\n  type        : \(.type // "<unknown>")\n  cloud       : \(.cloud // "<unknown>")\n  region      : \(.region // "<unknown>")\n  availability: \(.availability // "<unknown>")\n  status      : \(.status // "<unknown>")\n  endpoint    : \(.endpoint // "<unknown>")\n  rest        : \(.rest_endpoint // "<unknown>")"'
        else
            echo "  [WARN] Could not describe cluster."
        fi
    else
        echo "  [SKIP] CLUSTER_ID not set"
    fi

    echo ""
    echo "==> Schema Registry (Confluent Cloud)"
    sr_json="$(confluent schema-registry cluster describe -o json 2>/dev/null || true)"
    if [ -n "$sr_json" ]; then
        echo "$sr_json" | jq -r '"  id       : \(.id // "<unknown>")\n  url      : \(.endpoint_url // "<unknown>")\n  cloud    : \(.cloud // "<unknown>")\n  region   : \(.region // "<unknown>")"'
    else
        echo "  [WARN] Could not describe Schema Registry (maybe not enabled)."
    fi

    echo ""
    echo "==> API key ownership"
    owner_err_file="$(mktemp)"
    owner_json="$(confluent api-key describe "$KSHARK_KEY" -o json 2>"$owner_err_file" || true)"
    owner_err="$(cat "$owner_err_file")"
    rm -f "$owner_err_file"
    if [ -z "$owner_json" ]; then
        echo "  [WARN] Could not describe API key (check CLI auth/context)."
        if [ -n "${owner_err:-}" ]; then
            echo "  [WARN] describe error: ${owner_err}"
        fi
    else
        if ! echo "$owner_json" | jq -e . >/dev/null 2>&1; then
            echo "  [WARN] API key describe output is not valid JSON:"
            echo "  [WARN] ${owner_json}"
            owner_json="{}"
        fi
        if [ -n "${KS_DEBUG_DUMP_APIKEY_JSON:-}" ]; then
            echo "  [DEBUG] api-key describe raw JSON:"
            echo "$owner_json"
        fi

        mapfile -t parsed < <(echo "$owner_json" | jq -r '
            if type=="array" then (.[0] // {})
            elif type=="object" then .
            else {} end
            | [
                (.owner.id? // .spec.owner.id? //
                 (if (.owner|type)=="string" then .owner else empty end) //
                 (if (.spec.owner|type)=="string" then .spec.owner else empty end) // ""),
                (.owner.type? // .spec.owner.type? // ""),
                (.resource.id? // .spec.resource.id? //
                 (if (.resource|type)=="string" then .resource else empty end) //
                 (if (.spec.resource|type)=="string" then .spec.resource else empty end) // "")
              ] | .[]')
        owner_id="${parsed[0]:-}"
        resource_id="${parsed[2]:-}"
        echo "  owner.id       : ${owner_id:-<unknown>}"
        echo "  resource.id    : ${resource_id:-<unknown>}"
        if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ] && [ "$owner_id" != "$KAFKA_SERVICE_ACCOUNT_ID" ]; then
            echo "  [WARN] API key owner does not match service account ID."
        fi
        if [ -n "${CLUSTER_ID:-}" ] && [ "$resource_id" != "$CLUSTER_ID" ]; then
            echo "  [WARN] API key resource does not match CLUSTER_ID."
        fi
    fi

    echo ""
    echo "==> ACLs for service account (if available)"
    if [ -n "${KAFKA_SERVICE_ACCOUNT_ID:-}" ]; then
        confluent kafka acl list ${ENV_ID:+--environment "$ENV_ID"} ${CLUSTER_ID:+--cluster "$CLUSTER_ID"} \
            --principal "User:${KAFKA_SERVICE_ACCOUNT_ID}" || true
    else
        echo "  [SKIP] KAFKA_SERVICE_ACCOUNT_ID not set"
    fi

    echo ""
    echo "==> ACLs for API key principal (fallback check)"
    confluent kafka acl list ${ENV_ID:+--environment "$ENV_ID"} ${CLUSTER_ID:+--cluster "$CLUSTER_ID"} \
        --principal "User:${KSHARK_KEY}" || true

    echo ""
    echo "==> Demo topics (Confluent Cloud)"
    for t in payments fraud-alerts approved-payments; do
        topic_json="$(confluent kafka topic describe "$t" -o json 2>/dev/null || true)"
        if [ -n "$topic_json" ]; then
            name="$(echo "$topic_json" | jq -r '.name // .topic_name // "'"$t"'"')"
            partitions="$(echo "$topic_json" | jq -r '.partition_count // .partitions | if type=="array" then length else . end')"
            cleanup="$(echo "$topic_json" | jq -r '.configs["cleanup.policy"] // empty')"
            retention="$(echo "$topic_json" | jq -r '.configs["retention.ms"] // empty')"
            echo "  $name: partitions=${partitions:-<unknown>} cleanup=${cleanup:-<unknown>} retention.ms=${retention:-<unknown>}"
        else
            echo "  [WARN] Topic not found or not accessible: $t"
        fi
    done
else
    echo "[WARN] confluent or jq not found; skipping API key/ACL inspection."
fi
