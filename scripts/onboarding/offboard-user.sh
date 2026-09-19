#!/usr/bin/env bash
# Remove a user from a role group, or from every role group when no role is
# given. Removes membership only; it never touches role definitions or the
# groups themselves. Needs `az login` with rights to manage the membership.
#
#   ENV=prod ./offboard-user.sh alice@example.com dev   # one role
#   ENV=prod ./offboard-user.sh alice@example.com        # all roles
set -euo pipefail

PREFIX="${PREFIX:-astst}"
ENVIRONMENT="${ENV:-prod}"
ALL_ROLES="readonly dev ops dba security"

die() { echo "error: $*" >&2; exit 1; }

UPN="${1:-}"
ROLE="${2:-}"
[ -n "$UPN" ] || die "usage: [ENV=prod] $0 <user-principal-name> [role]"

if [ -n "$ROLE" ]; then
  case "$ROLE" in
    readonly | dev | ops | dba | security) ROLES="$ROLE" ;;
    *) die "unknown role '$ROLE' (expected readonly|dev|ops|dba|security)" ;;
  esac
else
  ROLES="$ALL_ROLES"
fi

command -v az >/dev/null 2>&1 || die "missing dependency: az"
az account show >/dev/null 2>&1 || die "not logged in -- run 'az login'"

USER_ID=$(az ad user show --id "$UPN" --query id -o tsv 2>/dev/null) || die "user not found: $UPN"

for r in $ROLES; do
  GROUP="${PREFIX}-${ENVIRONMENT}-${r}"
  GROUP_ID=$(az ad group show --group "$GROUP" --query id -o tsv 2>/dev/null) || { echo "skip: group not found: $GROUP"; continue; }
  if az ad group member check --group "$GROUP_ID" --member-id "$USER_ID" --query value -o tsv 2>/dev/null | grep -qi true; then
    az ad group member remove --group "$GROUP_ID" --member-id "$USER_ID"
    echo "removed $UPN from $GROUP"
  else
    echo "not a member: $UPN in $GROUP"
  fi
done
