#!/usr/bin/env bash
# Open a psql session to the private PostgreSQL server.
# Requires: (1) a network path to the private DB -- run from inside the VNet
# (VPN/Bastion) or from the backup container; (2) read access to the DB secrets
# in Key Vault (your IP allowed on the KV + Key Vault Secrets User).
#   ./db-connect.sh            # interactive psql
#   ./db-connect.sh "select now()"
set -euo pipefail
cd "$(dirname "$0")"; . ./_lib.sh
require_az; need psql

kv="$(kv_name)"; [ -n "$kv" ] || die "no Key Vault found in $RG"
get() { az keyvault secret show --vault-name "$kv" -n "$1" --query value -o tsv; }

echo "# fetching DB credentials from $kv" >&2
host="$(get DBHOST)"; user="$(get DBUSER)"; db="$(get DB)"; port="$(get DBPORT)"
export PGPASSWORD; PGPASSWORD="$(get DBPASS)"; PGSSLMODE=require

if [ -n "${1:-}" ]; then
  psql "host=$host port=$port dbname=$db user=$user sslmode=require" -c "$1"
else
  psql "host=$host port=$port dbname=$db user=$user sslmode=require"
fi
