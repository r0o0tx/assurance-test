#!/usr/bin/env bash
# Daily logical backup of the application database to versioned blob storage.
# DB credentials are read from Key Vault using the attached managed identity;
# nothing sensitive is passed in the environment.
set -euo pipefail

# Retry: IMDS can be briefly unavailable right after a container (re)start.
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

TS="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="/tmp/appdb-${TS}.sql.gz"

export PGPASSWORD="$DBPASS"
export PGSSLMODE=require
# --no-owner/--no-acl keep the dump portable: it restores into any target
# without ownership or catalog-grant noise that the restoring role cannot apply.
pg_dump --no-owner --no-acl -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d "$DB" | gzip >"$FILE"

# Retry the upload: the managed-identity token endpoint can be briefly
# unavailable right after a container (re)start, same as the login above.
for i in 1 2 3 4 5; do
  az storage blob upload \
    --account-name "$BACKUP_SA" --container-name backups \
    --name "appdb/${TS}.sql.gz" --file "$FILE" --auth-mode login --overwrite && break
  echo "upload attempt $i failed; retrying in 10s"
  sleep 10
done

echo "uploaded appdb/${TS}.sql.gz"
