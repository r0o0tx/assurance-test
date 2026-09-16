#!/usr/bin/env bash
# Daily logical backup of the application database to versioned blob storage.
# DB credentials are read from Key Vault using the attached managed identity;
# nothing sensitive is passed in the environment.
set -euo pipefail

az login --identity --client-id "$IDENTITY_CLIENT_ID" --output none

DBHOST=$(az keyvault secret show --vault-name "$KV_NAME" --name DBHOST --query value -o tsv)
DB=$(az keyvault secret show --vault-name "$KV_NAME" --name DB --query value -o tsv)
DBUSER=$(az keyvault secret show --vault-name "$KV_NAME" --name DBUSER --query value -o tsv)
DBPASS=$(az keyvault secret show --vault-name "$KV_NAME" --name DBPASS --query value -o tsv)
DBPORT=$(az keyvault secret show --vault-name "$KV_NAME" --name DBPORT --query value -o tsv)

TS="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="/tmp/appdb-${TS}.sql.gz"

export PGPASSWORD="$DBPASS"
pg_dump -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d "$DB" | gzip >"$FILE"

az storage blob upload \
  --account-name "$BACKUP_SA" --container-name backups \
  --name "appdb/${TS}.sql.gz" --file "$FILE" --auth-mode login --overwrite

echo "uploaded appdb/${TS}.sql.gz"
