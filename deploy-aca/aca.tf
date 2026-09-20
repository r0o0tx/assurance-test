data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group
}

# User-assigned identity used by both apps to pull from the shared registry.
resource "azurerm_user_assigned_identity" "aca" {
  name                = "${var.prefix}-id"
  resource_group_name = azurerm_resource_group.aca.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "aca_acr" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.prefix}-env"
  resource_group_name        = azurerm_resource_group.aca.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.infra.id
  tags                       = local.tags
}

resource "azurerm_container_app" "api" {
  name                         = "api"
  resource_group_name          = azurerm_resource_group.aca.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  secret {
    name  = "dbpass"
    value = random_password.db.result
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 2
    max_replicas = 5

    container {
      name   = "api"
      image  = "${data.azurerm_container_registry.shared.login_server}/api:${var.api_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      env {
        name  = "DB"
        value = "appdb"
      }
      env {
        name  = "DBUSER"
        value = "appadmin"
      }
      env {
        name  = "DBHOST"
        value = azurerm_postgresql_flexible_server.db.fqdn
      }
      env {
        name  = "DBPORT"
        value = "5432"
      }
      env {
        name        = "DBPASS"
        secret_name = "dbpass"
      }
      # Flexible Server requires TLS by default; the api enables SSL when set.
      env {
        name  = "DBSSL"
        value = "require"
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = 50
    }
  }

  depends_on = [azurerm_role_assignment.aca_acr, azurerm_postgresql_flexible_server_database.app]
}

resource "azurerm_container_app" "web" {
  name                         = "web"
  resource_group_name          = azurerm_resource_group.aca.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 2
    max_replicas = 5

    container {
      name   = "web"
      image  = "${data.azurerm_container_registry.shared.login_server}/web:${var.web_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3000"
      }
      env {
        name  = "API_HOST"
        value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = 50
    }
  }

  depends_on = [azurerm_role_assignment.aca_acr]
}
