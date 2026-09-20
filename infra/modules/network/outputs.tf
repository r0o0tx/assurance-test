output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "vnet_cidr" {
  value = var.vnet_cidr
}

output "web_subnet_id" {
  value = azurerm_subnet.web.id
}

output "api_subnet_id" {
  value = azurerm_subnet.api.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "jobs_subnet_id" {
  value = azurerm_subnet.jobs.id
}

output "api_subnet_cidr" {
  value = var.api_subnet_cidr
}

output "pg_dns_zone_id" {
  value = azurerm_private_dns_zone.pg.id
}

output "pg_dns_zone_link_id" {
  value = azurerm_private_dns_zone_virtual_network_link.pg.id
}
