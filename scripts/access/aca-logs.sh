#!/usr/bin/env bash
# Stream logs from a Container Apps (ACA) tier.
#   ./aca-logs.sh web        # follow web app logs
#   ./aca-logs.sh api
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az
tier="${1:?usage: aca-logs.sh <web|api>}"
aca_rg="rg-assurance-test-aca"
app="$(az containerapp list -g "$aca_rg" --query "[?contains(name,'${tier}')].name | [0]" -o tsv 2>/dev/null)"
[ -n "$app" ] || die "no '${tier}' container app in $aca_rg (is the ACA variant deployed?)"
az containerapp logs show -g "$aca_rg" -n "$app" --follow --tail 100
