# In-VNet backup runner: reaches the private DB, dumps immediately on start and
# every 24h, uploads to versioned blob storage. Runs entirely inside the VNet.
resource "azurerm_container_group" "backup" {
  name                = "${var.short_prefix}-backup"
  resource_group_name = var.rg
  location            = var.location
  os_type             = "Linux"
  restart_policy      = "Always"
  ip_address_type     = "Private"
  subnet_ids          = [var.jobs_subnet_id]
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Ship container stdout/stderr to Log Analytics so backup success/failure is queryable.
  diagnostics {
    log_analytics {
      workspace_id  = var.law_workspace_id
      workspace_key = var.law_workspace_key
    }
  }

  image_registry_credential {
    server                    = var.acr_login_server
    user_assigned_identity_id = var.identity_id
  }

  container {
    name     = "backup"
    image    = "${var.acr_login_server}/backup:${var.image_tag}"
    cpu      = "0.5"
    memory   = "1.0"
    commands = ["/bin/bash", "-c", "while true; do /usr/local/bin/pg_backup.sh || true; sleep 86400; done"]

    environment_variables = {
      KV_NAME            = var.key_vault_name
      BACKUP_SA          = azurerm_storage_account.backup.name
      IDENTITY_CLIENT_ID = var.identity_client_id
    }

    ports {
      port     = 8080
      protocol = "TCP"
    }
  }

  depends_on = [azurerm_role_assignment.backup_writer]
}
