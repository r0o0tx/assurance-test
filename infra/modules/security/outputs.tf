output "identity_id" {
  value = azurerm_user_assigned_identity.vmss.id
}

output "identity_principal_id" {
  value = azurerm_user_assigned_identity.vmss.principal_id
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.vmss.client_id
}

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

# Consumers depend on this to ensure KV RBAC has propagated before writing secrets.
output "kv_rbac_ready" {
  value = time_sleep.kv_rbac.id
}
