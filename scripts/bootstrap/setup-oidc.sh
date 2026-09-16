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

# Subject prefix. GitHub may issue an immutable subject that embeds numeric org/repo
# IDs (repo:owner@<orgid>/repo@<repoid>). If so, pass the exact prefix, e.g.:
#   SUB_PREFIX='repo:owner@123/repo@456' bash setup-oidc.sh
# Check the current value with:
#   gh api repos/$GH_ORG/$GH_REPO/actions/oidc/customization/sub
SUB_PREFIX="${SUB_PREFIX:-repo:${GH_ORG}/${GH_REPO}}"

APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
az ad sp create --id "$APP_ID" >/dev/null

az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gh-main\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"${SUB_PREFIX}:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gh-env-prod\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"${SUB_PREFIX}:environment:prod\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

# Roles scoped to the single resource group:
#  - Contributor: manage resources
#  - User Access Administrator: create the Key Vault / ACR role assignments Terraform defines
#  - AcrPush: push images from CI
#  - Storage Blob Data Contributor: AAD auth to the Terraform state container
#  - Key Vault Secrets Officer: read/manage the DB secrets Terraform maintains
SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${RG}"
for ROLE in "Contributor" "User Access Administrator" "AcrPush" "Storage Blob Data Contributor" "Key Vault Secrets Officer"; do
  az role assignment create --assignee "$APP_ID" --role "$ROLE" --scope "$SCOPE"
done

echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUB_ID"
echo "Set these as GitHub repo variables on ${GH_ORG}/${GH_REPO}."
