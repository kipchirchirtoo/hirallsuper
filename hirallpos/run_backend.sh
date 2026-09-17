#!/usr/bin/env bash
# ====================================================================
# Run Giftmart Supermarket Backend (hirall-backend Rust Axum Engine)
# ====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../hirall-backend"

cd "$BACKEND_DIR"

echo "=========================================================="
echo "🚀 Starting Giftmart Supermarket Rust Backend (Axum)..."
echo "📍 Base API URL:   http://127.0.0.1:8080/api/v1"
echo "🩺 Health Check:   http://127.0.0.1:8080/health"
echo "🛒 Client Org:     Giftmart Supermarket Ltd (GIFTMART)"
echo "=========================================================="

cargo run --bin hirall-backend
