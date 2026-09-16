#!/usr/bin/env bash
# Restore a named backup blob into the application database.
# Usage: pg_restore.sh appdb/20260915T091500Z.sql.gz
set -euo pipefail

BLOB="${1:?usage: pg_restore.sh <blob-name>}"

for i in 1 2 3 4 5; do
  az login --identity --client-id "$IDENTITY_CLIENT_ID" --output none && break
  echo "az login attempt $i failed; retrying in 10s"
  sleep 10
done

DBHOST=$(az keyvault secret show --vault-name "$KV_NAME" --name DBHOST --query value -o tsv)
DB=$(az keyvault secret show --vault-name "$KV_NAME" --name DB --query value -o tsv)
DBUSER=$(az keyvault secret show --vault-name "$KV_NAME" --name DBUSER --query value -o tsv)
DBPASS=$(az keyvault secret show --vault-name "$KV_NAME" --name DBPASS --query value -o tsv)
DBPORT=$(az keyvault secret show --vault-name "$KV_NAME" --name DBPORT --query value -o tsv)

az storage blob download --account-name "$BACKUP_SA" --container-name backups \
  --name "$BLOB" --file /tmp/restore.sql.gz --auth-mode login

export PGPASSWORD="$DBPASS"
gunzip -c /tmp/restore.sql.gz | psql -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d "$DB"

echo "restored $BLOB"
