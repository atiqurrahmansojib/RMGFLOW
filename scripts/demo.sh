#!/usr/bin/env bash
# One-command demo: starts Postgres, the RMGFlow backend with demo data, and serves
# the APK over the LAN so a phone on the same Wi-Fi can install it.
#
#   ./scripts/demo.sh          start everything (Ctrl+C stops backend + APK server)
#   ./scripts/demo.sh build    rebuild the APK for this machine's current LAN IP first
#
# Demo port is 8090 so it never collides with a dev backend on 8080.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${DEMO_PORT:-8090}"
IP="$(hostname -I | awk '{print $1}')"
FLUTTER_BIN="${FLUTTER_BIN:-$HOME/development/flutter/bin}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"

# Stable JWT secret outside the repo, so phone sessions survive backend restarts.
SECRET_FILE="$HOME/.rmgflow-demo-jwt"
[ -f "$SECRET_FILE" ] || { openssl rand -base64 48 > "$SECRET_FILE"; chmod 600 "$SECRET_FILE"; }

if [ "${1:-}" = "build" ]; then
  echo "==> Building APK for http://$IP:$PORT/api/v1 (from the current mobile/ code)"
  (cd "$ROOT/mobile" && PATH="$PATH:$FLUTTER_BIN" flutter build apk --release \
    --dart-define=API_BASE_URL="http://$IP:$PORT/api/v1")
  cp "$ROOT/mobile/build/app/outputs/flutter-apk/app-release.apk" "$ROOT/demo/rmgflow-demo.apk"
fi

echo "==> Starting database"
docker start rmgflow-postgres >/dev/null

# Runs the tested, frozen build in demo/ (not the working tree), so unfinished
# code in backend/ can never break a demo.
DEMO_DIR="$ROOT/demo"
LOG="$DEMO_DIR/demo-backend.log"
: > "$LOG"
echo "==> Starting backend on port $PORT with demo data (log: $LOG)"
(cd "$DEMO_DIR" && \
  SERVER_PORT="$PORT" DEMO_DATA=true \
  DB_URL=jdbc:postgresql://localhost:5434/rmgflow_demo DB_USERNAME=rmgflow DB_PASSWORD=rmgflow_dev_password \
  JWT_SECRET="$(cat "$SECRET_FILE")" \
  exec java -Xmx768m -jar rmgflow-demo.jar > "$LOG" 2>&1) &
BACKEND_PID=$!

(cd "$DEMO_DIR" && exec python3 -m http.server 8081 --bind 0.0.0.0 >/dev/null 2>&1) &
HTTP_PID=$!
# Stop only what this script started (never pkill by class name: that would also kill a dev backend).
stop_tree() { local p=$1; for c in $(pgrep -P "$p" 2>/dev/null); do stop_tree "$c"; done; kill "$p" 2>/dev/null || true; }
trap 'echo; echo "==> Stopping"; stop_tree $HTTP_PID; stop_tree $BACKEND_PID' EXIT INT TERM

echo "==> Waiting for backend..."
until grep -q "Started RmgflowApplication" "$LOG" 2>/dev/null; do
  if grep -q "APPLICATION FAILED" "$LOG" || ! kill -0 $BACKEND_PID 2>/dev/null 2>/dev/null; then echo "Backend failed, see $LOG"; exit 1; fi
  sleep 2
done

cat <<EOF

  RMGFlow demo is running.
  Install on phone (same Wi-Fi):  http://$IP:8081/rmgflow-demo.apk
  Backend API:                     http://$IP:$PORT/api/v1
  Demo logins (password Demo@1234): owner@rmgflow.test, sr.merch@rmgflow.test,
    quality@rmgflow.test, commercial@rmgflow.test, accounts@rmgflow.test, viewer@rmgflow.test
  If the APK was built for a different IP, run: ./scripts/demo.sh build

  Press Ctrl+C to stop.
EOF
wait $BACKEND_PID
