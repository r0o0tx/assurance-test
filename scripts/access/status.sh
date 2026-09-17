#!/usr/bin/env bash
# One-shot health snapshot across the stack: Front Door, both scale sets, the
# database, and the latest backup. Degrades gracefully when a check is blocked.
#   ENV=prod ./status.sh
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az

echo "== environment: ${ENVIRONMENT} (${RG}) =="

host="$(fd_host)"
if [ -n "$host" ]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0' "https://${host}/health" || echo "---")"
  echo "front door : https://${host}  /health -> ${code}"
else
  echo "front door : (not found)"
fi

for tier in web api; do
  vmss="$(vmss_name "$tier")"
  n="$(az vmss list-instances -g "$RG" -n "$vmss" --query "length(@)" -o tsv 2>/dev/null || echo 0)"
  hp="$(az vmss get-instance-view -g "$RG" -n "$vmss" \
        --query "statuses[?starts_with(code,'ProvisioningState')].displayStatus | [0]" -o tsv 2>/dev/null || echo "?")"
  echo "${tier} vmss   : ${n} instance(s), ${hp}"
done

db="$(db_name)"
if [ -n "$db" ]; then
  st="$(az postgres flexible-server show -g "$RG" -n "$db" --query state -o tsv 2>/dev/null || echo "?")"
  ha="$(az postgres flexible-server show -g "$RG" -n "$db" --query "highAvailability.state" -o tsv 2>/dev/null || echo "-")"
  echo "database   : ${db} state=${st} ha=${ha}"
fi

sa="$(backup_sa)"
if [ -n "$sa" ]; then
  last="$(az storage blob list --account-name "$sa" --container-name backups --auth-mode login \
          --query "sort_by([], &properties.lastModified)[-1].name" -o tsv 2>/dev/null || echo "")"
  echo "backup     : ${sa}  latest=${last:-<blocked or none>}"
fi
