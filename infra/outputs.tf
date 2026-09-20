# Outputs are added as modules land (front door hostname, tier FQDNs, db name,
# acr login server, log analytics id, backup storage account).
output "resource_group" {
  value = local.rg
}

output "location" {
  value = local.location
}

output "acr_login_server" {
  value = module.registry.login_server
}

output "acr_name" {
  value = module.registry.acr_name
}

output "key_vault_name" {
  value = module.security.key_vault_name
}

output "db_server_name" {
  value = module.data.db_server_name
}

output "db_fqdn" {
  value = module.data.db_fqdn
}

output "web_public_fqdn" {
  value = module.compute.web_public_fqdn
}

output "api_public_fqdn" {
  value = module.compute.api_public_fqdn
}

output "api_internal_ip" {
  value = module.compute.api_internal_ip
}

output "frontdoor_hostname" {
  value = module.edge.frontdoor_hostname
}

output "law_id" {
  value = module.observability.law_id
}

output "backup_sa" {
  value = module.backup.backup_sa
}

output "rbac_group_names" {
  description = "Role slug -> Entra group display name (empty unless rbac_enabled)."
  value       = var.rbac_enabled ? module.rbac[0].group_names : {}
}

output "bastion_id" {
  description = "Developer Bastion resource id (null unless bastion_enabled)."
  value       = module.access.bastion_id
}
