#!/usr/bin/env bash
# Query recent Syslog (host + container) from Log Analytics. Needs Log Analytics
# Reader on the workspace. Management plane -- works from anywhere.
#   ./logs.sh                 # last 100 lines, all tiers
#   ./logs.sh web             # filter to the web scale set
#   ./logs.sh api --tail      # poll every 15s
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az

tier="${1:-}"; [ "$tier" = "--tail" ] && { tier=""; tail=1; }
[ "${2:-}" = "--tail" ] && tail=1
guid="$(law_guid)"; [ -n "$guid" ] || die "no Log Analytics workspace in $RG"

filter=""
[ -n "$tier" ] && filter="| where Computer startswith \"${PREFIX}-${tier}\""
q="Syslog ${filter} | project TimeGenerated, Computer, SyslogMessage | order by TimeGenerated desc | take 100"

run() { az monitor log-analytics query -w "$guid" --analytics-query "$q" \
          --query "reverse([].{t:TimeGenerated, c:Computer, m:SyslogMessage})" -o tsv; }

if [ "${tail:-0}" = "1" ]; then
  echo "# tailing Syslog${tier:+ ($tier)} -- Ctrl-C to stop" >&2
  while true; do run; sleep 15; done
else
  run
fi
