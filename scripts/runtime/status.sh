#!/usr/bin/env bash
# Show instances, health/provisioning state, and latest-model status per tier.
set -euo pipefail
RG="${RG:-rg-assurance-test-prod}"
for TIER in web api; do
  echo "== ${TIER} =="
  az vmss list-instances -g "$RG" -n "astst-${TIER}-vmss" \
    --query "[].{id:instanceId, state:provisioningState, latestModel:latestModelApplied}" -o table
  az vmss get-instance-view -g "$RG" -n "astst-${TIER}-vmss" \
    --query "orchestrationServices" -o table 2>/dev/null || true
  echo ""
done
