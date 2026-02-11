#!/usr/bin/env bash
# ==============================================================================
# ccloud-cleanup.sh — Tear down Confluent Cloud resources for this toolkit
#
# Usage:
#   ./scripts/ccloud-cleanup.sh <environment-name>
# ==============================================================================
set -euo pipefail

ENV_NAME="${1:?Usage: $0 <environment-name>}"
ENV_FULL_NAME="payment-pipeline-$ENV_NAME"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $1"
        exit 1
    fi
}

require_cmd confluent
require_cmd jq

echo "==> Cleaning up Confluent Cloud environment: $ENV_FULL_NAME"

ENV_ID=$(confluent environment list -o json | jq -r --arg name "$ENV_FULL_NAME" '.[] | select(.name == $name) | .id' | head -n 1)
if [ -z "$ENV_ID" ]; then
    echo "[INFO] Environment not found: $ENV_FULL_NAME"
    exit 0
fi

echo "Environment ID: $ENV_ID"

# Confirm destructive action
if [ -t 0 ]; then
    read -r -p "This will delete environment '$ENV_FULL_NAME' and all resources. Type DELETE to continue: " CONFIRM
else
    CONFIRM="${CONFIRM_DELETE:-}"
fi

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Aborted. Set CONFIRM_DELETE=DELETE to run non-interactively."
    exit 1
fi

confluent environment delete "$ENV_ID" --force | tee /tmp/ccloud-env-delete.txt >/dev/null

echo "Deleted environment: $ENV_FULL_NAME ($ENV_ID)"
