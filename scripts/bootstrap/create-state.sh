#!/usr/bin/env bash
# One-time: create the single resource group and the Terraform state storage.
# These are intentionally NOT managed by Terraform so `terraform destroy` never
# removes the state behind it. Run once, then record the printed values.
set -euo pipefail

LOCATION="${LOCATION:-eastus}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
RG="${RG:-rg-assurance-test-${ENVIRONMENT}}"
PREFIX="${PREFIX:-asttstate}"
SUFFIX="$(openssl rand -hex 3)"
SA="${PREFIX}${SUFFIX}"
CONTAINER="tfstate"

az group create --name "$RG" --location "$LOCATION" \
  --tags app=assurance-test "env=${ENVIRONMENT}" managed-by=bootstrap owner=platform-team

az storage account create --name "$SA" --resource-group "$RG" \
  --location "$LOCATION" --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false

# Versioning + soft delete so shared team state has history and is recoverable.
az storage account blob-service-properties update \
  --account-name "$SA" --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 14 \
  --enable-container-delete-retention true --container-delete-retention-days 14

# Let the current signed-in user use AAD auth against the state container
# (the Terraform azurerm backend is configured with use_azuread_auth).
USER_OBJ="$(az ad signed-in-user show --query id -o tsv)"
SA_ID="$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)"
az role assignment create --assignee "$USER_OBJ" \
  --role "Storage Blob Data Contributor" --scope "$SA_ID"

az storage container create --name "$CONTAINER" \
  --account-name "$SA" --auth-mode login

# Lock the state data plane down to this caller's IP, then default-deny public
# access. Do this AFTER the container exists to avoid a network-rule propagation
# race. CI adds the runner IP the same way at deploy time and removes it after.
MYIP="$(curl -s ifconfig.me)"
az storage account network-rule add --account-name "$SA" --resource-group "$RG" --ip-address "$MYIP"
az storage account update --name "$SA" --resource-group "$RG" \
  --default-action Deny --bypass AzureServices

echo "STATE_STORAGE_ACCOUNT=$SA"
echo "STATE_RG=$RG"
echo "STATE_CONTAINER=$CONTAINER"
echo "Record STATE_STORAGE_ACCOUNT and STATE_RG for terraform init and CI variables."
