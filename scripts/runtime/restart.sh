#!/usr/bin/env bash
# Rolling restart of all instances in a tier's scale set.
# Usage: restart.sh <web|api>
set -euo pipefail
RG="${RG:-rg-assurance-test-prod}"
TIER="${1:?usage: restart.sh <web|api>}"
az vmss restart -g "$RG" -n "astst-${TIER}-vmss"
echo "restarted ${TIER}"
