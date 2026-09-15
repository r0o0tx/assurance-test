#!/usr/bin/env bash
# Set the instance count for a tier's scale set.
# Usage: scale.sh <web|api> <count>
set -euo pipefail
RG="${RG:-rg-assurance-test-prod}"
TIER="${1:?usage: scale.sh <web|api> <count>}"
COUNT="${2:?usage: scale.sh <web|api> <count>}"
az vmss scale -g "$RG" -n "astst-${TIER}-vmss" --new-capacity "$COUNT"
echo "scaled ${TIER} to ${COUNT}"
