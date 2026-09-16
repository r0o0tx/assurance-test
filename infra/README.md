# Infrastructure

Terraform for the `assurance-test` platform. All resources live in a single resource
group; the group and the Terraform state storage are created once by the bootstrap script
and are not managed by Terraform (so `terraform destroy` never removes state).

## Prerequisites

- Terraform >= 1.6
- Azure CLI, authenticated: `az login` (in CI this is done by the OIDC login step)
- An SSH public key for the VMSS admin account

## One-time bootstrap (creates the resource group + state storage)

```bash
LOCATION=eastus bash ../scripts/bootstrap/create-state.sh
# note the printed STATE_STORAGE_ACCOUNT
```

## Initialize (partial backend config supplied at init time)

```bash
terraform init \
  -backend-config="resource_group_name=rg-assurance-test-prod" \
  -backend-config="storage_account_name=<STATE_STORAGE_ACCOUNT>"
```

## Plan / apply

```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/astst.pub)"
terraform apply \
  -var "web_image_tag=<git-sha>" \
  -var "api_image_tag=<git-sha>"
```

Deploys of new application versions are just an apply with new image tags; the scale sets
roll the change out with a health-gated rolling upgrade (no downtime).

## Teardown

```bash
terraform destroy
az group delete -n rg-assurance-test-prod   # removes residual + state storage
```
