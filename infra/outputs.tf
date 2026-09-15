# Outputs are added as modules land (front door hostname, tier FQDNs, db name,
# acr login server, log analytics id, backup storage account).
output "resource_group" {
  value = local.rg
}

output "location" {
  value = local.location
}
