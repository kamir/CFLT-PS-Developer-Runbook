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

# 1. Create or select environment
echo "--- Creating environment..."
confluent environment create "payment-pipeline-$ENV_NAME" -o json | tee /tmp/ccloud-env.json
ENV_ID=$(cat /tmp/ccloud-env.json | grep '"id"' | head -1 | cut -d'"' -f4)
confluent environment use "$ENV_ID"
echo "  Environment ID: $ENV_ID"

# 2. Create Kafka cluster (basic for dev, dedicated for prod)
echo "--- Creating Kafka cluster..."
CLUSTER_TYPE="basic"
if [ "$ENV_NAME" = "prod" ] || [ "$ENV_NAME" = "qa" ]; then
    CLUSTER_TYPE="dedicated"
fi

if [ "$CLUSTER_TYPE" = "dedicated" ]; then
    confluent kafka cluster create "payment-cluster-$ENV_NAME" \
        --cloud aws \
        --region us-east-1 \
        --type dedicated \
        --cku 1 \
        -o json | tee /tmp/ccloud-cluster.json
else
    confluent kafka cluster create "payment-cluster-$ENV_NAME" \
        --cloud aws \
        --region us-east-1 \
        --type basic \
        -o json | tee /tmp/ccloud-cluster.json
fi

CLUSTER_ID=$(cat /tmp/ccloud-cluster.json | grep '"id"' | head -1 | cut -d'"' -f4)
confluent kafka cluster use "$CLUSTER_ID"
echo "  Cluster ID: $CLUSTER_ID"

# 3. Create API key for the cluster
echo "--- Creating API key..."
confluent api-key create --resource "$CLUSTER_ID" -o json | tee /tmp/ccloud-apikey.json
API_KEY=$(cat /tmp/ccloud-apikey.json | grep '"api_key"' | cut -d'"' -f4)
API_SECRET=$(cat /tmp/ccloud-apikey.json | grep '"api_secret"' | cut -d'"' -f4)

# 4. Enable Schema Registry
echo "--- Enabling Schema Registry..."
confluent schema-registry cluster enable --cloud aws --geo us -o json | tee /tmp/ccloud-sr.json

# 5. Create Schema Registry API key
echo "--- Creating Schema Registry API key..."
SR_CLUSTER_ID=$(cat /tmp/ccloud-sr.json | grep '"id"' | head -1 | cut -d'"' -f4)
confluent api-key create --resource "$SR_CLUSTER_ID" -o json | tee /tmp/ccloud-sr-apikey.json
SR_KEY=$(cat /tmp/ccloud-sr-apikey.json | grep '"api_key"' | cut -d'"' -f4)
SR_SECRET=$(cat /tmp/ccloud-sr-apikey.json | grep '"api_secret"' | cut -d'"' -f4)

# 6. Create topics
echo "--- Creating topics..."
for topic in payments fraud-alerts approved-payments; do
    confluent kafka topic create "$topic" --partitions 6 --if-not-exists
    echo "  [OK] $topic"
done

# 7. Output configuration summary
BOOTSTRAP=$(confluent kafka cluster describe "$CLUSTER_ID" -o json | grep '"endpoint"' | cut -d'"' -f4 | sed 's|SASL_SSL://||')
SR_URL=$(confluent schema-registry cluster describe -o json | grep '"endpoint_url"' | cut -d'"' -f4)

echo ""
echo "=============================================="
echo "  Confluent Cloud Setup Complete: $ENV_NAME"
echo "=============================================="
echo ""
echo "  Bootstrap Servers : $BOOTSTRAP"
echo "  API Key           : $API_KEY"
echo "  Schema Registry   : $SR_URL"
echo "  SR API Key        : $SR_KEY"
echo ""
echo "  Set these environment variables:"
echo ""
echo "  export KAFKA_BOOTSTRAP_SERVERS=\"$BOOTSTRAP\""
echo "  export KAFKA_SASL_JAAS_CONFIG=\"org.apache.kafka.common.security.plain.PlainLoginModule required username='$API_KEY' password='$API_SECRET';\""
echo "  export SCHEMA_REGISTRY_URL=\"$SR_URL\""
echo "  export SCHEMA_REGISTRY_USER_INFO=\"$SR_KEY:$SR_SECRET\""
echo ""
echo "  WARNING: Store API secrets securely (Vault, K8s Secrets). Never commit them."
