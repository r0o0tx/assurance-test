terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
  }
}

# Authentication uses the Azure CLI credential chain:
#   - locally:  `az login`
#   - in CI:    azure/login (OIDC federation) leaves the CLI authenticated
provider "azurerm" {
  features {
    key_vault {
      # The deploy identity is least-privileged and is not granted the vault
      # purge action. Leave vaults soft-deleted on destroy so teardown completes
      # cleanly; soft-deleted vaults are free and recoverable within retention.
      purge_soft_delete_on_destroy = false
    }
  }
  # Empty uses the CLI default subscription; set per-env for multi-subscription.
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

# Same CLI credential chain; used for the optional Entra ID role groups.
provider "azuread" {}
