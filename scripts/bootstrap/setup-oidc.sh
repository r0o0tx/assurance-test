#!/usr/bin/env bash
# One-time: create the Entra app + federated credentials for GitHub OIDC and
# grant it the roles the pipeline needs, scoped to the single resource group.
set -euo pipefail

APP_NAME="${APP_NAME:-assurance-test-cicd}"
RG="${RG:-rg-assurance-test-prod}"
GH_ORG="${GH_ORG:-r0o0tx}"
GH_REPO="${GH_REPO:-assurance-test}"
SUB_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
az ad sp create --id "$APP_ID" >/dev/null

az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gh-main\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GH_ORG}/${GH_REPO}:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gh-env-prod\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GH_ORG}/${GH_REPO}:environment:prod\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

# Roles scoped to the single resource group:
#  - Contributor: manage resources
#  - User Access Administrator: create the Key Vault / ACR role assignments Terraform defines
#  - AcrPush: push images from CI
#  - Storage Blob Data Contributor: AAD auth to the Terraform state container
SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${RG}"
for ROLE in "Contributor" "User Access Administrator" "AcrPush" "Storage Blob Data Contributor"; do
  az role assignment create --assignee "$APP_ID" --role "$ROLE" --scope "$SCOPE"
done

echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUB_ID"
echo "Set these as GitHub repo variables on ${GH_ORG}/${GH_REPO}."
