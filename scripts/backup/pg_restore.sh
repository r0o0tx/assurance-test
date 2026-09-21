#!/usr/bin/env bash
# Restore a named backup blob into a target database.
# The target defaults to a verification database, not the live application
# database: a restore should be validated in isolation before it is promoted,
# so it never overwrites the source it was taken from. Pass an explicit target
# to restore somewhere specific.
# Usage: pg_restore.sh appdb/20260915T091500Z.sql.gz [target-db]
set -euo pipefail

BLOB="${1:?usage: pg_restore.sh <blob-name> [target-db]}"

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

TARGET_DB="${2:-${DB}_restore_verify}"

for i in 1 2 3 4 5; do
  az storage blob download --account-name "$BACKUP_SA" --container-name backups \
    --name "$BLOB" --file /tmp/restore.sql.gz --auth-mode login && break
  echo "download attempt $i failed; retrying in 10s"
  sleep 10
done

export PGPASSWORD="$DBPASS"
export PGSSLMODE=require

if [ -z "${2:-}" ]; then
  # Default verification target: recreate it clean on every run so the drill is
  # repeatable and a restore always lands in an empty database.
  psql -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d postgres \
    -c "DROP DATABASE IF EXISTS \"$TARGET_DB\""
  psql -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d postgres \
    -c "CREATE DATABASE \"$TARGET_DB\""
else
  # Explicit target: create only if missing; never drop a caller-named database.
  EXISTS=$(psql -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname='$TARGET_DB'")
  if [ "$EXISTS" != "1" ]; then
    psql -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d postgres \
      -c "CREATE DATABASE \"$TARGET_DB\""
  fi
fi

# ON_ERROR_STOP so a partial or failed restore is a hard failure, not silent.
gunzip -c /tmp/restore.sql.gz | psql -v ON_ERROR_STOP=1 \
  -h "$DBHOST" -p "${DBPORT:-5432}" -U "$DBUSER" -d "$TARGET_DB"

echo "restored $BLOB into $TARGET_DB"
