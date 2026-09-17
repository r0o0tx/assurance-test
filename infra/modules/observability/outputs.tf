output "law_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "law_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "law_workspace_guid" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

output "law_primary_shared_key" {
  value     = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive = true
}
