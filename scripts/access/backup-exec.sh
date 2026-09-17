#!/usr/bin/env bash
# Run a command inside the in-VNet backup container (management plane).
#   ./backup-exec.sh                       # trigger a backup now
#   ./backup-exec.sh "ls -la /tmp"
# Note: use bash/PowerShell, not Git Bash, or the /usr path gets mangled.
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az
cmd="${1:-/usr/local/bin/pg_backup.sh}"
aci="$(backup_aci)"
echo "# exec in $aci: $cmd" >&2
az container exec -g "$RG" -n "$aci" --exec-command "$cmd"
