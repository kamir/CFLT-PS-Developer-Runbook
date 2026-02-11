#!/usr/bin/env bash
# ==============================================================================
# create-client-properties.sh — Generate Kafka client.properties from .env
#
# Usage:
#   ./scripts/create-client-properties.sh [output-file]
#   ENV_FILE=/path/to/.env ./scripts/create-client-properties.sh /tmp/client.properties
# ==============================================================================
set -euo pipefail

OUT_FILE="${1:-client.properties}"

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

if [ -f "$ENV_FILE" ]; then
    load_env_file "$ENV_FILE"
fi

BOOTSTRAP="${KAFKA_BOOTSTRAP_SERVERS:-}"
SEC_PROTOCOL="${KAFKA_SECURITY_PROTOCOL:-SASL_SSL}"
SASL_MECH="${KAFKA_SASL_MECHANISM:-PLAIN}"
SASL_JAAS="${KAFKA_SASL_JAAS_CONFIG:-}"
KAFKA_USER="${KAFKA_SERVICE_ACCOUNT_KEY:-}"
KAFKA_PASS="${KAFKA_SERVICE_ACCOUNT_SECRET:-}"

SR_URL="${SCHEMA_REGISTRY_URL:-}"
SR_USER_INFO="${SCHEMA_REGISTRY_SERVICE_ACCOUNT_KEY:-}:${SCHEMA_REGISTRY_SERVICE_ACCOUNT_SECRET:-}"

if [ -z "$BOOTSTRAP" ]; then
    echo "[ERROR] KAFKA_BOOTSTRAP_SERVERS not set (from $ENV_FILE)" >&2
    exit 1
fi
if [ -z "$KAFKA_USER" ] || [ -z "$KAFKA_PASS" ]; then
    echo "[ERROR] Service account credentials not set (KAFKA_SERVICE_ACCOUNT_KEY/SECRET) in $ENV_FILE" >&2
    exit 1
fi

{
    echo "# Kafka Cluster Connection"
    echo "# Service Account credentials (required for demos and kshark)"
    echo "bootstrap.servers=$BOOTSTRAP"
    echo "security.protocol=$SEC_PROTOCOL"
    echo "sasl.mechanism=$SASL_MECH"
    if [ -n "$SASL_JAAS" ]; then
        echo "sasl.jaas.config=$SASL_JAAS"
    fi
    if [ -n "$KAFKA_USER" ]; then
        echo "sasl.username=$KAFKA_USER"
    fi
    if [ -n "$KAFKA_PASS" ]; then
        echo "sasl.password=$KAFKA_PASS"
    fi
    echo ""
    echo "# Schema Registry Connection"
    if [ -n "$SR_URL" ]; then
        if [ -z "$SR_USER_INFO" ] || [ "$SR_USER_INFO" = ":" ]; then
            echo "[ERROR] Service account SR credentials not set (SCHEMA_REGISTRY_SERVICE_ACCOUNT_KEY/SECRET) in $ENV_FILE" >&2
            exit 1
        fi
        echo "schema.registry.url=$SR_URL"
        echo "basic.auth.credentials.source=USER_INFO"
        if [ -n "$SR_USER_INFO" ]; then
            echo "basic.auth.user.info=$SR_USER_INFO"
        fi
    fi
} > "$OUT_FILE"

echo "Wrote $OUT_FILE"
