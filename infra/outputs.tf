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
