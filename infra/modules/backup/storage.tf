resource "azurerm_storage_account" "backup" {
  name                            = "${var.short_prefix}bkp${var.suffix}"
  resource_group_name             = var.rg
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }

    container_delete_retention_policy {
      days = 14
    }
  }
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# The backup job identity can write blobs.
resource "azurerm_role_assignment" "backup_writer" {
  scope                = azurerm_storage_account.backup.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}
