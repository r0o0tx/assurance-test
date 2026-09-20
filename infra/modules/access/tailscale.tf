# Tailscale subnet router. This is a capability demonstration, not part of the
# core access path: it is off by default, has no public IP, and is never the
# primary way in. When enabled it advertises the VNet range to the tailnet so an
# operator on the tailnet can reach the private subnets.
locals {
  tailscale_count = var.tailscale_enabled ? 1 : 0
}

resource "azurerm_subnet" "tailscale" {
  count                = local.tailscale_count
  name                 = "snet-tailscale"
  resource_group_name  = var.rg
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.tailscale_subnet_cidr]
}

resource "azurerm_network_interface" "tailscale" {
  count               = local.tailscale_count
  name                = "${var.short_prefix}-ts-nic"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  # A subnet router forwards traffic for other addresses, so the NIC must permit it.
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tailscale[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "tailscale" {
  count               = local.tailscale_count
  name                = "${var.short_prefix}-ts-router"
  resource_group_name = var.rg
  location            = var.location
  size                = var.tailscale_vm_size
  admin_username      = "azureuser"
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.tailscale[0].id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init-tailscale.yaml.tftpl", {
    authkey  = var.tailscale_auth_key
    routes   = var.vnet_cidr
    hostname = "${var.short_prefix}-ts-router"
  }))
}
