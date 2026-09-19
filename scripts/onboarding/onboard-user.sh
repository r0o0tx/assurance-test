#!/usr/bin/env bash
# Add a user to one of the environment's role groups. Access follows from group
# membership -- no per-user role assignments. Needs `az login` as someone who
# can manage the group's membership (group owner or a directory role).
#
#   ENV=prod ./onboard-user.sh alice@example.com dev
#
# Roles: readonly | dev | ops | dba | security
set -euo pipefail

PREFIX="${PREFIX:-astst}"
ENVIRONMENT="${ENV:-prod}"

die() { echo "error: $*" >&2; exit 1; }

UPN="${1:-}"
ROLE="${2:-}"
[ -n "$UPN" ] && [ -n "$ROLE" ] || die "usage: [ENV=prod] $0 <user-principal-name> <readonly|dev|ops|dba|security>"

case "$ROLE" in
  readonly | dev | ops | dba | security) ;;
  *) die "unknown role '$ROLE' (expected readonly|dev|ops|dba|security)" ;;
esac

command -v az >/dev/null 2>&1 || die "missing dependency: az"
az account show >/dev/null 2>&1 || die "not logged in -- run 'az login'"

GROUP="${PREFIX}-${ENVIRONMENT}-${ROLE}"

USER_ID=$(az ad user show --id "$UPN" --query id -o tsv 2>/dev/null) || die "user not found: $UPN"
GROUP_ID=$(az ad group show --group "$GROUP" --query id -o tsv 2>/dev/null) || die "group not found: $GROUP (is rbac_enabled applied for env '$ENVIRONMENT'?)"

if az ad group member check --group "$GROUP_ID" --member-id "$USER_ID" --query value -o tsv 2>/dev/null | grep -qi true; then
  echo "already a member: $UPN in $GROUP"
  exit 0
fi

az ad group member add --group "$GROUP_ID" --member-id "$USER_ID"
echo "added $UPN to $GROUP"
