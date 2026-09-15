# The resource group is created once by scripts/bootstrap/create-state.sh (it also
# holds the Terraform state storage). Terraform consumes it as a data source so a
# `terraform destroy` never removes the group or the state behind it.
data "azurerm_resource_group" "main" {
  name = var.resource_group
}

# Short random suffix for globally-unique names (storage, acr, front door, db).
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  rg       = data.azurerm_resource_group.main.name
  location = var.location
  suffix   = random_string.suffix.result
  tags     = var.tags
}

# Module blocks are wired in as each module lands:
#   network -> security -> registry -> data -> compute -> edge -> observability -> backup

module "network" {
  source       = "./modules/network"
  rg           = local.rg
  location     = local.location
  tags         = local.tags
  short_prefix = var.short_prefix
}
