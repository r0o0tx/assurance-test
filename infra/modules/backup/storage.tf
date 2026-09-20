resource "azurerm_storage_account" "backup" {
  name                            = "${var.short_prefix}bkp${var.suffix}"
  resource_group_name             = var.rg
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
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

  # Default-deny the data plane. The backup job reaches it over the jobs subnet
  # service endpoint; the deployer is allowed by IP so the container resource can
  # be managed during apply. ip_rules is set to the current deployer IP each run.
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.jobs_subnet_id]
    ip_rules                   = var.deployer_ip_rules
  }
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# The backup job identity can write blobs, scoped to the backups container, not
# the whole account (least privilege).
resource "azurerm_role_assignment" "backup_writer" {
  scope                = azurerm_storage_container.backups.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}
