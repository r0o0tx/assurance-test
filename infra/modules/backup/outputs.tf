output "backup_sa" {
  value = azurerm_storage_account.backup.name
}

output "backup_container" {
  value = azurerm_storage_container.backups.name
}
