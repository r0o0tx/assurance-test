#!/usr/bin/env bash
# Interactive shell on a VMSS instance. Instances have no public IP, so this
# tunnels through Azure Bastion when one is present in the group. For one-off
# commands without Bastion, use ./vm-exec.sh instead (management plane).
#   ./connect-vm.sh web        # first instance
#   ./connect-vm.sh api 3
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az

tier="${1:?usage: connect-vm.sh <web|api> [instance-id]}"
vmss="$(vmss_name "$tier")"
inst="${2:-$(az vmss list-instances -g "$RG" -n "$vmss" --query "[0].instanceId" -o tsv)}"
vm_id="$(az vmss list-instances -g "$RG" -n "$vmss" --query "[?instanceId=='${inst}'].id | [0]" -o tsv)"
[ -n "$vm_id" ] || die "instance $inst not found on $vmss"

bastion="$(az network bastion list -g "$RG" --query "[0].name" -o tsv 2>/dev/null || true)"
if [ -n "$bastion" ]; then
  echo "# tunnelling via bastion $bastion" >&2
  az network bastion ssh --name "$bastion" -g "$RG" \
    --target-resource-id "$vm_id" --auth-type ssh-key \
    --username azureuser --ssh-key ~/.ssh/astst
else
  cat >&2 <<EOF
No Bastion found in $RG. Interactive SSH needs private access (see task B:
Bastion Developer / Tailscale). For one-off commands use:
  ./vm-exec.sh $tier $inst "<command>"
EOF
  exit 2
fi
