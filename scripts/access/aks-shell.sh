#!/usr/bin/env bash
# Configure kubectl for the AKS variant and drop into a shell (or run a command).
#   ./aks-shell.sh                 # get-credentials + kubectl get pods
#   ./aks-shell.sh "kubectl get deploy -A"
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az; need kubectl
aks_rg="rg-assurance-test-aks"
name="$(az aks list -g "$aks_rg" --query "[0].name" -o tsv 2>/dev/null)"
[ -n "$name" ] || die "no AKS cluster in $aks_rg (is the AKS variant deployed?)"
az aks get-credentials -g "$aks_rg" -n "$name" --overwrite-existing
${1:-kubectl get pods -o wide}
