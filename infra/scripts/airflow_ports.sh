#!/usr/bin/env bash
set -euo pipefail

BASE_PORT="${AIRFLOW_WEB_BASE_PORT:-8080}"
current_port="${BASE_PORT}"

is_port_free() {
  local port="$1"
  python - "${port}" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.bind(("127.0.0.1", port))
except OSError:
    sys.exit(1)
finally:
    sock.close()
PY
}

while ! is_port_free "${current_port}"; do
  current_port=$((current_port + 1))
done

echo "${current_port}"
