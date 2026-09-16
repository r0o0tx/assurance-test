output "web_url" {
  value = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}

output "api_url" {
  value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "resource_group" {
  value = azurerm_resource_group.aca.name
}
