resource "azurerm_container_registry" "main" {
  name                = "${var.short_prefix}acr${var.suffix}"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false
  tags                = var.tags

  # Reap untagged manifests so superseded image layers do not linger.
  retention_policy {
    days    = 7
    enabled = true
  }
}

# VMSS instances pull images with their managed identity (no registry passwords).
resource "azurerm_role_assignment" "vmss_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.vmss_principal_id
}
