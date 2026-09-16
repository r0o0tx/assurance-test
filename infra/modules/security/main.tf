data "azurerm_client_config" "current" {}

# Identity attached to the VMSS instances: pulls images from ACR and reads Key
# Vault secrets at boot. No credentials ever live on disk.
resource "azurerm_user_assigned_identity" "vmss" {
  name                = "id-${var.short_prefix}-vmss"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags
}

resource "azurerm_key_vault" "main" {
  name                       = "${var.short_prefix}-kv-${var.suffix}"
  resource_group_name        = var.rg
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

# VMSS identity can read secrets.
resource "azurerm_role_assignment" "vmss_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.vmss.principal_id
}

# The identity that bootstraps the stack can write secrets (DB creds, etc.).
# Additional runners (e.g. the CI service principal) are granted separately in the
# OIDC setup. principal_id is ignored on updates so the assignment does not churn
# when a different identity (local vs CI) runs a later apply.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id

  lifecycle {
    ignore_changes = [principal_id]
  }
}

# RBAC assignments can take up to ~1 minute to propagate to the data plane; wait
# so the first secret writes in the data module do not 403.
resource "time_sleep" "kv_rbac" {
  depends_on      = [azurerm_role_assignment.deployer_secrets_officer]
  create_duration = "60s"
}
