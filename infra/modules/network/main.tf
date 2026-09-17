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
  # Reach Key Vault (secret fetch at boot) and Storage over the backbone, not the
  # public endpoint, so those data planes can default-deny public network access.
  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "api" {
  name                 = "snet-api"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.api_subnet_cidr]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
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

# NAT subnet for the Private Link Services that expose the tier load balancers to
# Front Door privately. Private Link Service requires network policies disabled.
resource "azurerm_subnet" "pls" {
  name                                          = "snet-pls"
  resource_group_name                           = var.rg
  virtual_network_name                          = azurerm_virtual_network.main.name
  address_prefixes                              = [var.pls_subnet_cidr]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "jobs" {
  name                 = "snet-jobs"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.jobs_subnet_cidr]
  # The backup job reads Key Vault and writes backup blobs over the backbone.
  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

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
    name                       = "allow-pls"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = var.pls_subnet_cidr
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
# API tier NSG: Private Link edge + the web subnet (east-west); deny direct net.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "api" {
  name                = "nsg-api"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "allow-pls"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = var.pls_subnet_cidr
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

  # The in-VNet backup job (jobs subnet) connects to the database on 5432.
  security_rule {
    name                       = "allow-jobs-postgres"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.jobs_subnet_cidr
    destination_address_prefix = "*"
  }

  # Flexible Server zone-redundant HA replicates between primary and standby within
  # the delegated subnet; this traffic must be allowed on 5432.
  security_rule {
    name                       = "allow-intra-db-postgres"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.db_subnet_cidr
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
