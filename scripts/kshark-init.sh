#!/usr/bin/env bash
# ==============================================================================
# kshark-init.sh — Download and install kshark into ./tools
#
# Usage:
#   ./scripts/kshark-init.sh
#   KSHARK_VERSION=0.25.4 ./scripts/kshark-init.sh
# ==============================================================================
set -euo pipefail

KSHARK_VERSION="${KSHARK_VERSION:-0.25.4}"
REPO="scalytics/kshark-core"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tools"
OUT_BIN="$TOOLS_DIR/kshark"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $1" >&2
        exit 1
    fi
}

require_cmd curl
require_cmd jq

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$OS" in
    darwin) OS_PAT="darwin|mac|osx" ;;
    linux)  OS_PAT="linux" ;;
    *) echo "[ERROR] Unsupported OS: $OS" >&2; exit 1 ;;
 esac
case "$ARCH" in
    x86_64|amd64) ARCH_PAT="amd64|x86_64" ;;
    arm64|aarch64) ARCH_PAT="arm64|aarch64" ;;
    *) echo "[ERROR] Unsupported arch: $ARCH" >&2; exit 1 ;;
 esac

API_URL="https://api.github.com/repos/$REPO/releases/tags/v$KSHARK_VERSION"

ASSET_URL=$(curl -fsSL "$API_URL" | jq -r --arg os_pat "$OS_PAT" --arg arch_pat "$ARCH_PAT" '
  .assets
  | map(select(.name | test($os_pat; "i")))
  | map(select(.name | test($arch_pat; "i")))
  | map(select(.name | test("kshark"; "i")))
  | sort_by(.name | if test("\\.tar\\.gz$|\\.tgz$") then 0 elif test("\\.zip$") then 1 else 2 end)
  | .[0].browser_download_url // empty
')

if [ -z "$ASSET_URL" ]; then
    echo "[ERROR] Could not find a matching kshark asset for OS=$OS ARCH=$ARCH in v$KSHARK_VERSION" >&2
    exit 1
fi

mkdir -p "$TOOLS_DIR"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

ASSET_FILE="$TMP_DIR/asset"

curl -fsSL "$ASSET_URL" -o "$ASSET_FILE"

case "$ASSET_URL" in
    *.tar.gz|*.tgz)
        tar -xzf "$ASSET_FILE" -C "$TMP_DIR"
        ;;
    *.zip)
        require_cmd unzip
        unzip -q "$ASSET_FILE" -d "$TMP_DIR"
        ;;
    *)
        ;;
 esac

if [ -f "$ASSET_FILE" ] && [ ! -f "$TMP_DIR/kshark" ]; then
    # Might be a raw binary
    cp "$ASSET_FILE" "$TMP_DIR/kshark" || true
fi

BIN_PATH=$(find "$TMP_DIR" -type f -name "kshark" | head -n 1)
if [ -z "$BIN_PATH" ]; then
    echo "[ERROR] kshark binary not found in downloaded asset" >&2
    exit 1
fi

cp "$BIN_PATH" "$OUT_BIN"
chmod +x "$OUT_BIN"

echo "Installed kshark to $OUT_BIN"
"$OUT_BIN" --version 2>/dev/null || true

if [ -x "$ROOT_DIR/scripts/create-client-properties.sh" ] && [ -f "$ROOT_DIR/.env" ]; then
    echo "Generating client.properties using service account credentials..."
    "$ROOT_DIR/scripts/create-client-properties.sh" "$ROOT_DIR/client.properties"
fi
