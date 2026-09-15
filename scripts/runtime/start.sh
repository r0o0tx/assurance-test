#!/usr/bin/env bash
# Start all instances in a tier's scale set.
# Usage: start.sh <web|api>
set -euo pipefail
RG="${RG:-rg-assurance-test-prod}"
TIER="${1:?usage: start.sh <web|api>}"
az vmss start -g "$RG" -n "astst-${TIER}-vmss"
echo "started ${TIER}"
