# Ship control-plane logs + metrics from every managed service to the workspace.

resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name                       = "fd-diag"
  target_resource_id         = var.frontdoor_profile_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "db" {
  name                       = "diag"
  target_resource_id         = var.db_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "diag"
  target_resource_id         = var.acr_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
}

# Load balancers expose metrics only (no diagnostic log categories).
resource "azurerm_monitor_diagnostic_setting" "web_lb" {
  name                       = "diag"
  target_resource_id         = var.web_lb_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "api_lb" {
  name                       = "diag"
  target_resource_id         = var.api_lb_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}
