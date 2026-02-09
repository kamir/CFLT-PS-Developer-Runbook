#!/usr/bin/env bash
# ==============================================================================
# create-topics.sh — Create Kafka topics for the payment pipeline
#
# Usage:
#   # Local (docker-compose):
#   ./scripts/create-topics.sh local
#
#   # Confluent Cloud:
#   ./scripts/create-topics.sh cloud
# ==============================================================================
set -euo pipefail

MODE="${1:-local}"

TOPICS=(
    "payments:6:3"
    "fraud-alerts:6:3"
    "approved-payments:6:3"
)

case "$MODE" in
    local)
        echo "==> Creating topics on local broker (localhost:9092)..."
        for entry in "${TOPICS[@]}"; do
            IFS=':' read -r topic partitions replication <<< "$entry"
            # local single-node: replication = 1
            docker exec broker kafka-topics --create \
                --bootstrap-server localhost:9092 \
                --topic "$topic" \
                --partitions "$partitions" \
                --replication-factor 1 \
                --if-not-exists \
                2>/dev/null && echo "  [OK] $topic" || echo "  [SKIP] $topic (already exists)"
        done
        ;;

    cloud)
        echo "==> Creating topics on Confluent Cloud..."
        if ! command -v confluent &>/dev/null; then
            echo "ERROR: 'confluent' CLI not found. Install from https://docs.confluent.io/confluent-cli/current/install.html"
            exit 1
        fi
        for entry in "${TOPICS[@]}"; do
            IFS=':' read -r topic partitions replication <<< "$entry"
            confluent kafka topic create "$topic" \
                --partitions "$partitions" \
                --if-not-exists \
                && echo "  [OK] $topic" || echo "  [SKIP] $topic"
        done
        ;;

    *)
        echo "Usage: $0 [local|cloud]"
        exit 1
        ;;
esac

echo "==> Done."
