resource "azurerm_container_registry" "main" {
  name                = "${var.short_prefix}acr${var.suffix}"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

# VMSS instances pull images with their managed identity (no registry passwords).
resource "azurerm_role_assignment" "vmss_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.vmss_principal_id
}
