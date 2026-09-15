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

module "compute" {
  source             = "./modules/compute"
  rg                 = local.rg
  location           = local.location
  tags               = local.tags
  short_prefix       = var.short_prefix
  suffix             = local.suffix
  vm_sku             = var.vm_sku
  ssh_public_key     = var.ssh_public_key
  identity_id        = module.security.identity_id
  identity_client_id = module.security.identity_client_id
  acr_login_server   = module.registry.login_server
  acr_name           = module.registry.acr_name
  key_vault_name     = module.security.key_vault_name
  web_subnet_id      = module.network.web_subnet_id
  api_subnet_id      = module.network.api_subnet_id
  web_instance_count = var.web_instance_count
  api_instance_count = var.api_instance_count
  web_image_tag      = var.web_image_tag
  api_image_tag      = var.api_image_tag

  # DB secrets must exist in Key Vault before instances boot and read them.
  depends_on = [module.data]
}
