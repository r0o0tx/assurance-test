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

module "security" {
  source       = "./modules/security"
  rg           = local.rg
  location     = local.location
  tags         = local.tags
  short_prefix = var.short_prefix
  suffix       = local.suffix
}

module "registry" {
  source            = "./modules/registry"
  rg                = local.rg
  location          = local.location
  tags              = local.tags
  short_prefix      = var.short_prefix
  suffix            = local.suffix
  vmss_principal_id = module.security.identity_principal_id
}

module "data" {
  source              = "./modules/data"
  rg                  = local.rg
  location            = local.location
  tags                = local.tags
  short_prefix        = var.short_prefix
  suffix              = local.suffix
  db_sku              = var.db_sku
  db_subnet_id        = module.network.db_subnet_id
  private_dns_zone_id = module.network.pg_dns_zone_id
  key_vault_id        = module.security.key_vault_id

  # Wait for the private DNS zone link (network) and KV RBAC propagation (security).
  depends_on = [module.network, module.security]
}
