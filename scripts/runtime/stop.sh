#!/usr/bin/env bash
# Stop (deallocate) all instances in a tier's scale set to release compute.
# Usage: stop.sh <web|api>
set -euo pipefail
RG="${RG:-rg-assurance-test-prod}"
TIER="${1:?usage: stop.sh <web|api>}"
az vmss deallocate -g "$RG" -n "astst-${TIER}-vmss"
echo "stopped (deallocated) ${TIER}"
