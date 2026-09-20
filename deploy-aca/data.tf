resource "random_password" "db" {
  length  = 24
  special = false
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                = "${var.prefix}-pg"
  resource_group_name = azurerm_resource_group.aca.name
  location            = var.location
  version             = "16"

  administrator_login    = "appadmin"
  administrator_password = random_password.db.result

  sku_name   = var.db_sku
  storage_mb = 32768
  zone       = "1"

  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.pg.id

  public_network_access_enabled = false

  dynamic "high_availability" {
    for_each = var.high_availability_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  tags                         = local.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.pg]
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
