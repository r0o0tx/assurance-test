output "bastion_id" {
  description = "Developer Bastion resource id, or null when disabled."
  value       = var.bastion_enabled ? azurerm_bastion_host.developer[0].id : null
}

output "tailscale_router_private_ip" {
  description = "Private IP of the showcase subnet router, or null when disabled."
  value       = var.tailscale_enabled ? azurerm_network_interface.tailscale[0].private_ip_address : null
}
