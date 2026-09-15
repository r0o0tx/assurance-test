# Partial backend config. The storage account + resource group are supplied at
# init time via -backend-config flags (see infra/README.md), so no environment
# specific values are committed. AAD auth avoids handling storage account keys.
terraform {
  backend "azurerm" {
    use_azuread_auth = true
    container_name   = "tfstate"
    key              = "prod.tfstate"
  }
}
