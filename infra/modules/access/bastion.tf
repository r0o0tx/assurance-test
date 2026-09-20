# Developer SKU Bastion: browser and CLI SSH to the private nodes with no public
# IP and no dedicated AzureBastionSubnet. It is free and is the demoable
# break-glass path. Gated so an environment can opt out.
resource "azurerm_bastion_host" "developer" {
  count               = var.bastion_enabled ? 1 : 0
  name                = "${var.short_prefix}-bastion"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Developer"
  virtual_network_id  = var.vnet_id
  tags                = var.tags
}
