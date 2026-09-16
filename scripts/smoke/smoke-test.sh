#!/usr/bin/env bash
# Post-deploy smoke test: exercise the public endpoints through Front Door.
# Usage: smoke-test.sh <frontdoor-hostname>
set -euo pipefail

FD="${1:?usage: smoke-test.sh <frontdoor-hostname>}"
RETRY=(--retry 20 --retry-delay 3 --retry-all-errors --retry-connrefused)

fail() {
  echo "SMOKE FAIL: $1"
  exit 1
}

echo -n "web /health    : "
curl -fsS "${RETRY[@]}" "https://$FD/health" || fail "web /health unreachable"
echo

echo -n "api /api/status: "
status=$(curl -fsS "${RETRY[@]}" "https://$FD/api/status") || fail "api /api/status unreachable"
echo "$status" | grep -q '"time"' || fail "api /api/status did not return a db time"
echo "ok (db reachable)"

echo -n "web render     : "
curl -fsS "https://$FD/" | grep -qi "3tier App" || fail "web did not render"
echo "ok"

echo "smoke test passed"
