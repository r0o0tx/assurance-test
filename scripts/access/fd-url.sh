#!/usr/bin/env bash
# Print the public Front Door URL for the environment.
#   ENV=prod ./fd-url.sh
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az
host="$(fd_host)"
[ -n "$host" ] || die "no Front Door endpoint found in $RG (is it deployed?)"
echo "https://${host}"
