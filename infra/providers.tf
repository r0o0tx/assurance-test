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
  }
}

# Authentication uses the Azure CLI credential chain:
#   - locally:  `az login`
#   - in CI:    azure/login (OIDC federation) leaves the CLI authenticated
provider "azurerm" {
  features {}
}
