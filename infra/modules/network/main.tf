resource "azurerm_virtual_network" "main" {
  name                = "${var.short_prefix}-vnet"
  resource_group_name = var.rg
  location            = var.location
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.web_subnet_cidr]
}

resource "azurerm_subnet" "api" {
  name                 = "snet-api"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.api_subnet_cidr]
}

resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_cidr]

  delegation {
    name = "pg"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "jobs" {
  name                 = "snet-jobs"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.jobs_subnet_cidr]

  delegation {
    name = "aci"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# ---------------------------------------------------------------------------
# Web tier NSG: inbound app traffic only from Front Door edge; deny direct net.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "allow-frontdoor"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-azure-lb"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-in"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ---------------------------------------------------------------------------
# API tier NSG: Front Door edge + the web subnet (east-west); deny direct net.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "api" {
  name                = "nsg-api"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "allow-frontdoor"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-azure-lb"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-web-subnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = var.web_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-in"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ---------------------------------------------------------------------------
# DB tier NSG: only the API subnet on 5432; everything else denied.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "db" {
  name                = "nsg-db"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "allow-api-postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.api_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-in"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "api" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# Private DNS for the PostgreSQL Flexible Server private endpoint.
resource "azurerm_private_dns_zone" "pg" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  name                  = "pg-link"
  resource_group_name   = var.rg
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}
