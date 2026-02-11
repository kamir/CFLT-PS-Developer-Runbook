#!/usr/bin/env bash
# ==============================================================================
# ccloud-setup.sh — Bootstrap a Confluent Cloud environment for this toolkit
#
# Prerequisites: confluent CLI installed and authenticated
# Usage:
#   ./scripts/ccloud-setup.sh <environment-name>  (e.g., dev, qa, prod)
# ==============================================================================
set -euo pipefail

ENV_NAME="${1:?Usage: $0 <environment-name>}"

echo "==> Setting up Confluent Cloud environment: $ENV_NAME"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $1"
        exit 1
    fi
}

require_cmd confluent
require_cmd jq

# Helpers for JSON parsing
jq_first_id_by_name() {
    local name="$1"
    jq -r --arg name "$name" '.[] | select(.name == $name) | .id' | head -n 1
}

# 0. Reuse existing environment if it already exists
ENV_FULL_NAME="payment-pipeline-$ENV_NAME"
ENV_ID=$(confluent environment list -o json | jq_first_id_by_name "$ENV_FULL_NAME" || true)

# 1. Create or select environment
echo "--- Creating environment..."
if [ -n "$ENV_ID" ]; then
    echo "  Environment already exists: $ENV_FULL_NAME ($ENV_ID)"
else
    confluent environment create "$ENV_FULL_NAME" -o json | tee /tmp/ccloud-env.json
    ENV_ID=$(jq -r '.id' /tmp/ccloud-env.json)
fi
confluent environment use "$ENV_ID"
echo "  Environment ID: $ENV_ID"

# 2. Create Kafka cluster (basic for dev, dedicated for prod)
echo "--- Creating Kafka cluster..."
CLUSTER_TYPE="basic"
if [ "$ENV_NAME" = "prod" ] || [ "$ENV_NAME" = "qa" ]; then
    CLUSTER_TYPE="dedicated"
fi
CLUSTER_NAME="payment-cluster-$ENV_NAME"
CLUSTER_ID=$(confluent kafka cluster list -o json | jq_first_id_by_name "$CLUSTER_NAME" || true)

if [ "$CLUSTER_TYPE" = "dedicated" ]; then
    if [ -n "$CLUSTER_ID" ]; then
        echo "  Cluster already exists: $CLUSTER_NAME ($CLUSTER_ID)"
    else
        confluent kafka cluster create "$CLUSTER_NAME" \
            --cloud aws \
            --region us-east-1 \
            --type dedicated \
            --cku 1 \
            -o json | tee /tmp/ccloud-cluster.json
        CLUSTER_ID=$(jq -r '.id' /tmp/ccloud-cluster.json)
    fi
else
    if [ -n "$CLUSTER_ID" ]; then
        echo "  Cluster already exists: $CLUSTER_NAME ($CLUSTER_ID)"
    else
        confluent kafka cluster create "$CLUSTER_NAME" \
            --cloud aws \
            --region us-east-1 \
            --type basic \
            -o json | tee /tmp/ccloud-cluster.json
        CLUSTER_ID=$(jq -r '.id' /tmp/ccloud-cluster.json)
    fi
fi
confluent kafka cluster use "$CLUSTER_ID"
echo "  Cluster ID: $CLUSTER_ID"

# 3. Create API key for the cluster
echo "--- Creating API key..."
API_KEY=""
API_SECRET=""
EXISTING_KEYS=$(confluent api-key list --resource "$CLUSTER_ID" -o json | jq -r '.[].key')
if [ -n "${EXISTING_KEYS:-}" ]; then
    API_KEY=$(echo "$EXISTING_KEYS" | head -n 1)
    echo "  Reusing existing API key: $API_KEY"
else
    confluent api-key create --resource "$CLUSTER_ID" -o json | tee /tmp/ccloud-apikey.json
    API_KEY=$(jq -r '.api_key' /tmp/ccloud-apikey.json)
    API_SECRET=$(jq -r '.api_secret' /tmp/ccloud-apikey.json)
fi

# 3b. Create service account + API key with admin topic permissions
echo "--- Creating service account for workload access..."
SA_NAME="payment-sa-$ENV_NAME"
SA_ID=$(confluent iam service-account list -o json | jq -r --arg name "$SA_NAME" '.[] | select(.name == $name) | .id' | head -n 1)
if [ -z "$SA_ID" ]; then
    confluent iam service-account create "$SA_NAME" --description "Service account for $ENV_FULL_NAME" -o json | tee /tmp/ccloud-sa.json
    SA_ID=$(jq -r '.id' /tmp/ccloud-sa.json)
fi
echo "  Service Account ID: $SA_ID"

echo "--- Creating service account API key..."
SA_API_KEY=""
SA_API_SECRET=""
SA_REUSE_EXISTING="${SA_REUSE_EXISTING:-false}"
SA_KEYS=$(confluent api-key list --resource "$CLUSTER_ID" -o json | jq -r --arg sa "$SA_ID" '
  .[] | select(
    ( ( .owner | type ) == "object" and .owner.id == $sa ) or
    ( ( .owner | type ) == "string" and .owner == $sa )
  ) | .key
')
if [ -n "${SA_KEYS:-}" ] && [ "$SA_REUSE_EXISTING" = "true" ]; then
    SA_API_KEY=$(echo "$SA_KEYS" | head -n 1)
    echo "  Reusing service account API key: $SA_API_KEY"
else
    confluent api-key create --service-account "$SA_ID" --resource "$CLUSTER_ID" -o json | tee /tmp/ccloud-sa-apikey.json
    SA_API_KEY=$(jq -r '.api_key' /tmp/ccloud-sa-apikey.json)
    SA_API_SECRET=$(jq -r '.api_secret' /tmp/ccloud-sa-apikey.json)
fi

echo "--- Applying ACLs for service account..."
print_acl_table() {
    local cmd=("$@")
    echo ""
    "${cmd[@]}"
    echo ""
}
for topic in payments fraud-alerts approved-payments; do
    print_acl_table confluent kafka acl create --allow --service-account "$SA_ID" \
        --operations read,write,describe,create,delete,alter,describe-configs,alter-configs \
        --topic "$topic"
done
print_acl_table confluent kafka acl create --allow --service-account "$SA_ID" \
    --operations read,describe \
    --consumer-group "*"
print_acl_table confluent kafka acl create --allow --service-account "$SA_ID" \
    --operations read,describe \
    --consumer-group "payment-consumer-group"
print_acl_table confluent kafka acl create --allow --service-account "$SA_ID" \
    --operations describe,cluster-action,idempotent-write \
    --cluster-scope

# Force service account key for app usage
if [ -n "$SA_API_KEY" ] && [ -n "$SA_API_SECRET" ]; then
    API_KEY="$SA_API_KEY"
    API_SECRET="$SA_API_SECRET"
else
    echo "[ERROR] Service account API key/secret not available; cannot update .env with SA credentials." >&2
    exit 1
fi

# Cluster metadata
CLUSTER_JSON=$(confluent kafka cluster describe "$CLUSTER_ID" -o json)
CLUSTER_CLOUD=$(echo "$CLUSTER_JSON" | jq -r '.cloud // empty')
CLUSTER_REGION=$(echo "$CLUSTER_JSON" | jq -r '.region // empty')

# 4. Schema Registry (managed; describe if available)
echo "--- Checking Schema Registry..."
SR_CLUSTER_ID=""
SR_KEY=""
SR_SECRET=""
if [ -n "${SR_ID:-}" ]; then
    SR_CLUSTER_ID="$SR_ID"
else
    if confluent schema-registry cluster describe -o json | tee /tmp/ccloud-sr.json >/dev/null; then
        SR_CLUSTER_ID=$(jq -r '.id // empty' /tmp/ccloud-sr.json)
    fi
fi

if [ -z "$SR_CLUSTER_ID" ] || [ "$SR_CLUSTER_ID" = "null" ]; then
    echo "  [WARN] Schema Registry is not enabled for this environment."
    echo "         You must enable Stream Governance (Essentials or Advanced) in Confluent Cloud."
    echo ""
    echo "         Steps:"
    echo "           1) Open https://confluent.cloud"
    echo "           2) Select environment: payment-pipeline-$ENV_NAME"
    echo "           3) Go to Stream Governance"
    echo "           4) Choose Essentials or Advanced and enable"
    echo ""
    echo "         This will provision Schema Registry for cloud='$CLUSTER_CLOUD' region='$CLUSTER_REGION'."
    echo "         When done, return here."
    echo ""
    read -r -p "Press ENTER after enabling Schema Registry in the console..." _unused

    if confluent schema-registry cluster describe -o json | tee /tmp/ccloud-sr.json >/dev/null; then
        SR_CLUSTER_ID=$(jq -r '.id // empty' /tmp/ccloud-sr.json)
    fi
fi

if [ -z "$SR_CLUSTER_ID" ] || [ "$SR_CLUSTER_ID" = "null" ]; then
    read -r -p "Enter Schema Registry ID (e.g., lsrc-xxxxx) or leave blank to skip: " SR_CLUSTER_ID
fi

if [ -n "$SR_CLUSTER_ID" ] && [ "$SR_CLUSTER_ID" != "null" ]; then
    echo "  Schema Registry ID: $SR_CLUSTER_ID"
    # 5. Create Schema Registry API key
    echo "--- Creating Schema Registry API key..."
    SR_KEY=""
    SR_SECRET=""
    SR_SA_KEYS=""
    if [ -n "${SA_ID:-}" ]; then
        SR_SA_KEYS=$(confluent api-key list --resource "$SR_CLUSTER_ID" -o json | jq -r --arg sa "$SA_ID" '
          .[] | select(
            ( ( .owner | type ) == "object" and .owner.id == $sa ) or
            ( ( .owner | type ) == "string" and .owner == $sa )
          ) | .key
        ')
    fi

    if [ -n "${SR_SA_KEYS:-}" ] && [ "${SA_REUSE_EXISTING:-false}" = "true" ]; then
        SR_KEY=$(echo "$SR_SA_KEYS" | head -n 1)
        echo "  Reusing service account SR API key: $SR_KEY"
    else
        if [ -n "${SA_ID:-}" ]; then
            confluent api-key create --service-account "$SA_ID" --resource "$SR_CLUSTER_ID" -o json | tee /tmp/ccloud-sr-apikey.json
        else
            confluent api-key create --resource "$SR_CLUSTER_ID" -o json | tee /tmp/ccloud-sr-apikey.json
        fi
        SR_KEY=$(jq -r '.api_key' /tmp/ccloud-sr-apikey.json)
        SR_SECRET=$(jq -r '.api_secret' /tmp/ccloud-sr-apikey.json)
    fi
else
    echo "  [WARN] Schema Registry still not enabled; skipping SR key creation."
fi

# 6. Create topics
echo "--- Creating topics..."
for topic in payments fraud-alerts approved-payments; do
    confluent kafka topic create "$topic" --partitions 6 --if-not-exists
    echo "  [OK] $topic"
done

# 7. Output configuration summary
BOOTSTRAP=$(echo "$CLUSTER_JSON" | jq -r '.endpoint' | sed 's|SASL_SSL://||')
SR_URL=""
if [ -n "$SR_CLUSTER_ID" ]; then
    SR_URL=$(confluent schema-registry cluster describe -o json | jq -r '.endpoint_url')
fi

echo ""
echo "=============================================="
echo "  Confluent Cloud Setup Complete: $ENV_NAME"
echo "=============================================="
echo ""
echo "  Bootstrap Servers : $BOOTSTRAP"
echo "  API Key           : $API_KEY"
echo "  Schema Registry   : ${SR_URL:-<not enabled>}"
echo "  SR API Key        : ${SR_KEY:-<not created>}"
echo ""
echo "  Set these environment variables:"
echo ""
echo "  export KAFKA_BOOTSTRAP_SERVERS=\"$BOOTSTRAP\""
echo "  export KAFKA_API_KEYS=\"${EXISTING_KEYS:-$API_KEY}\""
if [ -n "$API_SECRET" ]; then
    echo "  export KAFKA_SASL_JAAS_CONFIG=\"org.apache.kafka.common.security.plain.PlainLoginModule required username='$API_KEY' password='$API_SECRET';\""
else
    echo "  # KAFKA_SASL_JAAS_CONFIG not set (API secret unavailable for existing key)"
fi
if [ -n "$SR_URL" ]; then
    echo "  export SCHEMA_REGISTRY_URL=\"$SR_URL\""
    if [ -n "$SR_SECRET" ]; then
        echo "  export SCHEMA_REGISTRY_USER_INFO=\"$SR_KEY:$SR_SECRET\""
    else
        echo "  # SCHEMA_REGISTRY_USER_INFO not set (SR secret unavailable for existing key)"
    fi
    echo "  export SCHEMA_REGISTRY_API_KEYS=\"${EXISTING_SR_KEYS:-$SR_KEY}\""
else
    echo "  # SCHEMA_REGISTRY_URL and SCHEMA_REGISTRY_USER_INFO not set (SR not enabled)"
fi
echo ""
echo "  WARNING: Store API secrets securely (Vault, K8s Secrets). Never commit them."

# 8. Persist .env for app consumption
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

env_quote() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    echo "\"$v\""
}

{
    echo "# Generated by scripts/ccloud-setup.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "ENV_NAME=$(env_quote "$ENV_NAME")"
    echo "ENV_ID=$(env_quote "$ENV_ID")"
    echo "CLUSTER_ID=$(env_quote "$CLUSTER_ID")"
    echo "CLUSTER_CLOUD=$(env_quote "$CLUSTER_CLOUD")"
    echo "CLUSTER_REGION=$(env_quote "$CLUSTER_REGION")"
    echo "KAFKA_BOOTSTRAP_SERVERS=$(env_quote "$BOOTSTRAP")"
    echo "KAFKA_API_KEYS=$(env_quote "${EXISTING_KEYS:-$API_KEY}")"
    if [ -n "$API_SECRET" ]; then
        echo "KAFKA_API_KEY=$(env_quote "$API_KEY")"
        echo "KAFKA_API_SECRET=$(env_quote "$API_SECRET")"
        echo "KAFKA_SASL_JAAS_CONFIG=$(env_quote "org.apache.kafka.common.security.plain.PlainLoginModule required username='$API_KEY' password='$API_SECRET';")"
    fi
    if [ -n "$SA_ID" ]; then
        echo "KAFKA_SERVICE_ACCOUNT_ID=$(env_quote "$SA_ID")"
    fi
    if [ -n "$SA_API_KEY" ]; then
        echo "KAFKA_SERVICE_ACCOUNT_KEY=$(env_quote "$SA_API_KEY")"
    fi
    if [ -n "$SA_API_SECRET" ]; then
        echo "KAFKA_SERVICE_ACCOUNT_SECRET=$(env_quote "$SA_API_SECRET")"
    fi
    if [ -n "$SR_URL" ]; then
        echo "SCHEMA_REGISTRY_URL=$(env_quote "$SR_URL")"
        echo "SCHEMA_REGISTRY_API_KEYS=$(env_quote "${SR_SA_KEYS:-$SR_KEY}")"
        if [ -n "$SR_SECRET" ]; then
            echo "SCHEMA_REGISTRY_KEY=$(env_quote "$SR_KEY")"
            echo "SCHEMA_REGISTRY_SECRET=$(env_quote "$SR_SECRET")"
            echo "SCHEMA_REGISTRY_USER_INFO=$(env_quote "$SR_KEY:$SR_SECRET")"
        fi
        if [ -n "$SA_ID" ]; then
            echo "SCHEMA_REGISTRY_SERVICE_ACCOUNT_ID=$(env_quote "$SA_ID")"
        fi
        if [ -n "$SR_KEY" ]; then
            echo "SCHEMA_REGISTRY_SERVICE_ACCOUNT_KEY=$(env_quote "$SR_KEY")"
        fi
        if [ -n "$SR_SECRET" ]; then
            echo "SCHEMA_REGISTRY_SERVICE_ACCOUNT_SECRET=$(env_quote "$SR_SECRET")"
        fi
    fi
} > "$ENV_FILE"

echo "  Wrote environment file: $ENV_FILE"
