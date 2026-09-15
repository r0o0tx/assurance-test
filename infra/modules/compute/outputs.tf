output "web_public_fqdn" {
  value = azurerm_public_ip.web.fqdn
}

output "api_public_fqdn" {
  value = azurerm_public_ip.api.fqdn
}

output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "api_public_ip" {
  value = azurerm_public_ip.api.ip_address
}

output "api_internal_ip" {
  value = var.api_internal_ip
}

output "web_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.web.id
}

output "api_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.api.id
}

output "web_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.web.name
}

output "api_vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.api.name
}

output "web_lb_id" {
  value = azurerm_lb.web.id
}

output "api_lb_id" {
  value = azurerm_lb.api.id
}
