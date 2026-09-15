output "db_server_name" {
  value = azurerm_postgresql_flexible_server.db.name
}

output "db_fqdn" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

output "db_name" {
  value = azurerm_postgresql_flexible_server_database.app.name
}

output "db_id" {
  value = azurerm_postgresql_flexible_server.db.id
}
