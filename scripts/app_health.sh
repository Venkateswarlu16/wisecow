#!/usr/bin/env bash
# app_health.sh
# Checks one or more HTTP endpoints for expected status codes and logs results.
#
# Usage:
#   ./app_health.sh https://example.com:443=200 http://localhost:4499=200
# Or provide list via a file:
#   ./app_health.sh -f urls.txt
#
# The URL format supports optional expected status code after '=' (default 200).
# Example urls.txt:
# https://wisecow.local/=200
# http://127.0.0.1:4499/=200

LOGFILE="${APP_HEALTH_LOG:-$HOME/app_health.log}"
RETRIES="${RETRIES:-2}"
TIMEOUT="${TIMEOUT:-5}"   # curl timeout seconds
SILENT="${SILENT:-false}"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "$(timestamp) $*" >> "$LOGFILE"; }
alert() { echo "$(timestamp) ALERT: $*" >> "$LOGFILE"; if [ "$SILENT" != "true" ]; then echo "ALERT: $*"; fi }

check_one() {
  local url="$1"
  local expected="$2"
  local attempt=0
  local code
  while [ "$attempt" -le "$RETRIES" ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")
    if [ "$code" = "$expected" ]; then
      log "OK: $url returned $code (expected $expected)"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  alert "FAILED: $url returned $code (expected $expected) after $RETRIES retries"
  return 1
}

main() {
  mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
  urls=()

  if [ "$1" = "-f" ]; then
    [ -f "$2" ] || { echo "File not found: $2"; exit 2; }
    while IFS= read -r line; do
      line="${line%%#*}"
      line="${line## }"
      [ -z "$line" ] && continue
      urls+=("$line")
    done < "$2"
  else
    # parse args like url=200
    for a in "$@"; do
      urls+=("$a")
    done
  fi

  if [ "${#urls[@]}" -eq 0 ]; then
    echo "Usage: $0 url[=status] ...  OR $0 -f file"
    exit 2
  fi

  for u in "${urls[@]}"; do
    # split on =
    url="${u%%=*}"
    expected="${u#*=}"
    if [ "$expected" = "$u" ]; then expected="200"; fi
    check_one "$url" "$expected"
  done
}

main "$@"

