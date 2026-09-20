locals {
  rg_name = coalesce(var.resource_group, "rg-assurance-test-${var.environment}-aca")
  tags = {
    app        = "assurance-test"
    env        = var.environment
    managed-by = "terraform"
    owner      = "platform-team"
  }
}

resource "azurerm_resource_group" "aca" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.aca.name
  location            = var.location
  address_space       = ["10.60.0.0/16"]
  tags                = local.tags
}

# Container Apps environment requires a dedicated infrastructure subnet (min /23)
# delegated to the Container Apps service.
resource "azurerm_subnet" "infra" {
  name                 = "snet-aca"
  resource_group_name  = azurerm_resource_group.aca.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.60.0.0/23"]

  delegation {
    name = "aca"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.aca.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.60.2.0/24"]

  delegation {
    name = "pg"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "pg" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.aca.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  name                  = "pg-link"
  resource_group_name   = azurerm_resource_group.aca.name
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-law"
  resource_group_name = azurerm_resource_group.aca.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}
