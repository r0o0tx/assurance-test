output "web_internal_ip" {
  value = var.web_internal_ip
}

output "api_internal_ip" {
  value = var.api_internal_ip
}

output "web_pls_id" {
  value = azurerm_private_link_service.web.id
}

output "api_pls_id" {
  value = azurerm_private_link_service.api.id
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

output "api_internal_lb_id" {
  value = azurerm_lb.api_internal.id
}
