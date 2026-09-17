#!/usr/bin/env bash
# Run a shell command on a VMSS instance via the management plane (az vmss
# run-command) -- works with only RBAC, no VPN/Bastion/public IP.
#   ./vm-exec.sh web            # default diagnostic snapshot on instance 0-ish
#   ./vm-exec.sh api 3 "docker ps"
#   ./vm-exec.sh web "" "sudo journalctl -u docker --no-pager | tail -50"
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az

tier="${1:?usage: vm-exec.sh <web|api> [instance-id] [command]}"
inst="${2:-}"
cmd="${3:-echo \"== \$(hostname) ==\"; docker ps --format '{{.Names}}\t{{.Status}}'; curl -s localhost:3000/health || true}"
vmss="$(vmss_name "$tier")"

if [ -z "$inst" ]; then
  inst="$(az vmss list-instances -g "$RG" -n "$vmss" --query "[0].instanceId" -o tsv 2>/dev/null)"
  [ -n "$inst" ] || die "no instances found for $vmss"
fi

echo "# $vmss instance $inst" >&2
az vmss run-command invoke -g "$RG" -n "$vmss" --instance-id "$inst" \
  --command-id RunShellScript --scripts "$cmd" \
  --query "value[0].message" -o tsv
