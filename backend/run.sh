#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# .env 파일이 있으면 로드
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

PORT="${PORT:-3000}"
HOST="${HOST:-0.0.0.0}"

echo "=========================================="
echo " Starting PIPI Backend Server (FastAPI)"
echo " Host: http://${HOST}:${PORT}"
echo "=========================================="

python3 -m uvicorn server:app --host "$HOST" --port "$PORT"
