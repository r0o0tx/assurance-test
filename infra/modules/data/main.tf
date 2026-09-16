resource "random_password" "db" {
  length  = 24
  special = false
}

# Private, zone-redundant PostgreSQL. No public endpoint; only the API subnet can
# reach it (enforced by the DB NSG). General Purpose tier is required for
# zone-redundant HA (Burstable does not support it).
resource "azurerm_postgresql_flexible_server" "db" {
  name                = "${var.short_prefix}-pg-${var.suffix}"
  resource_group_name = var.rg
  location            = var.location
  version             = "16"

  administrator_login    = "appadmin"
  administrator_password = random_password.db.result

  sku_name   = var.db_sku
  storage_mb = 32768
  zone       = "1"

  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  public_network_access_enabled = false

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# TLS is enforced; the api connects with SSL (DBSSL=require in its environment).
resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "ON"
}

# Connection facts consumed by the API tier at boot (read via managed identity).
resource "azurerm_key_vault_secret" "db_host" {
  name         = "DBHOST"
  value        = azurerm_postgresql_flexible_server.db.fqdn
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "db_name" {
  name         = "DB"
  value        = "appdb"
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "DBUSER"
  value        = "appadmin"
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "db_pass" {
  name         = "DBPASS"
  value        = random_password.db.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "db_port" {
  name         = "DBPORT"
  value        = "5432"
  key_vault_id = var.key_vault_id
}
