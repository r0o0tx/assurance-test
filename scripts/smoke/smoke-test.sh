#!/usr/bin/env bash
# Post-deploy smoke test: exercise the public endpoints through Front Door.
# Usage: smoke-test.sh <frontdoor-hostname>
set -euo pipefail

FD="${1:?usage: smoke-test.sh <frontdoor-hostname>}"
RETRY="--retry 20 --retry-delay 3 --retry-all-errors --retry-connrefused"

echo -n "web /health   : "
curl -fsS $RETRY "https://$FD/health" && echo

echo -n "api /api/status: "
curl -fsS $RETRY "https://$FD/api/status" | grep -q '"time"' && echo "ok (db reachable)"

echo -n "web render    : "
curl -fsS "https://$FD/" | grep -qi "3tier App" && echo "ok"

echo "smoke test passed"
