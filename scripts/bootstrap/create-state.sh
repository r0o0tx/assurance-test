#!/usr/bin/env bash
# One-time: create the single resource group and the Terraform state storage.
# These are intentionally NOT managed by Terraform so `terraform destroy` never
# removes the state behind it. Run once, then record the printed values.
set -euo pipefail

LOCATION="${LOCATION:-southeastasia}"
RG="${RG:-rg-assurance-test-prod}"
PREFIX="${PREFIX:-asttstate}"
SUFFIX="$(tr -dc 'a-z0-9' </dev/urandom | head -c6)"
SA="${PREFIX}${SUFFIX}"
CONTAINER="tfstate"

az group create --name "$RG" --location "$LOCATION" \
  --tags app=assurance-test env=prod managed-by=bootstrap owner=shubham

az storage account create --name "$SA" --resource-group "$RG" \
  --location "$LOCATION" --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false

# Let the current signed-in user use AAD auth against the state container
# (the Terraform azurerm backend is configured with use_azuread_auth).
USER_OBJ="$(az ad signed-in-user show --query id -o tsv)"
SA_ID="$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)"
az role assignment create --assignee "$USER_OBJ" \
  --role "Storage Blob Data Contributor" --scope "$SA_ID"

az storage container create --name "$CONTAINER" \
  --account-name "$SA" --auth-mode login

echo "STATE_STORAGE_ACCOUNT=$SA"
echo "STATE_RG=$RG"
echo "STATE_CONTAINER=$CONTAINER"
echo "Record STATE_STORAGE_ACCOUNT and STATE_RG for terraform init and CI variables."
