#!/usr/bin/env bash
# Shared helpers for the access scripts. Resolves resource names by convention
# (prefix + environment) and az queries, so an operator only needs `az login`
# plus their role's RBAC -- no Terraform state access.
set -euo pipefail

PREFIX="${PREFIX:-astst}"
ENVIRONMENT="${ENV:-prod}"
# Override RG for non-standard groups; defaults to the project convention.
RG="${RG:-rg-assurance-test-${ENVIRONMENT}}"

die() { echo "error: $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

require_az() {
  need az
  az account show >/dev/null 2>&1 || die "not logged in -- run 'az login'"
}

# --- resolvers (query by convention; tolerate absence) ---
fd_profile() { echo "${PREFIX}-fd"; }

fd_host() {
  az afd endpoint list -g "$RG" --profile-name "$(fd_profile)" \
    --query "[0].hostName" -o tsv 2>/dev/null
}

kv_name() {
  az keyvault list -g "$RG" --query "[?starts_with(name,'${PREFIX}-kv')].name | [0]" -o tsv 2>/dev/null
}

db_name() {
  az postgres flexible-server list -g "$RG" \
    --query "[?starts_with(name,'${PREFIX}-pg')].name | [0]" -o tsv 2>/dev/null
}

backup_sa() {
  az storage account list -g "$RG" \
    --query "[?starts_with(name,'${PREFIX}bkp')].name | [0]" -o tsv 2>/dev/null
}

law_guid() {
  az monitor log-analytics workspace show -g "$RG" -n "${PREFIX}-law" \
    --query customerId -o tsv 2>/dev/null
}

vmss_name() { echo "${PREFIX}-${1:?tier}-vmss"; }
backup_aci() { echo "${PREFIX}-backup"; }
