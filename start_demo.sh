#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f "build/web/index.html" ]; then
  echo "Building Flutter Web release bundle..."
  flutter build web --release
fi

PORT="${PORT:-3000}"
lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true

python3 backend/server.py &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

sleep 1
echo "Local URL: http://localhost:$PORT"
if command -v ipconfig >/dev/null 2>&1; then
  LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || true)
  if [ -n "$LAN_IP" ]; then
    echo "Same Wi-Fi URL: http://$LAN_IP:$PORT"
  fi
fi

if command -v cloudflared >/dev/null 2>&1; then
  LOG_FILE=$(mktemp)
  cloudflared tunnel --url "http://localhost:$PORT" --no-autoupdate >"$LOG_FILE" 2>&1 &
  TUNNEL_PID=$!
  trap 'kill "$TUNNEL_PID" "$SERVER_PID" 2>/dev/null || true; rm -f "$LOG_FILE"' EXIT

  PUBLIC_URL=""
  for _ in $(seq 1 30); do
    PUBLIC_URL=$(grep -Eo 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$LOG_FILE" | head -n 1 || true)
    if [ -n "$PUBLIC_URL" ]; then
      break
    fi
    sleep 1
  done

  if [ -n "$PUBLIC_URL" ]; then
    echo ""
    echo "=========================================="
    echo "PIPI Public Demo URL: $PUBLIC_URL"
    echo "=========================================="
    if command -v qrencode >/dev/null 2>&1; then
      qrencode -t ANSIUTF8 "$PUBLIC_URL"
      qrencode -s 14 -m 3 -o demo_qr.png "$PUBLIC_URL"
      echo "Saved QR image: $(pwd)/demo_qr.png"
      open demo_qr.png 2>/dev/null || true
    fi
  else
    echo "Cloudflare Tunnel URL timeout. Check $LOG_FILE"
  fi
  wait "$TUNNEL_PID"
else
  echo "cloudflared not found. Keeping local server running..."
  wait "$SERVER_PID"
fi
