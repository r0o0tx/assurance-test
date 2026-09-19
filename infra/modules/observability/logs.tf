resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.short_prefix}-law"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}

# The Azure Monitor Agent identity must be allowed to publish telemetry.
resource "azurerm_role_assignment" "ama_publisher" {
  scope                = azurerm_log_analytics_workspace.main.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = var.identity_principal_id
}

# Collect host + container syslog (docker uses the syslog log driver) off-box.
resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "${var.short_prefix}-dcr-syslog"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  destinations {
    log_analytics {
      name                  = "law"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law"]
  }

  data_sources {
    syslog {
      name           = "syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["daemon", "user", "syslog", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7"]
      log_levels     = var.syslog_log_levels
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "web" {
  name                    = "dcra-web"
  target_resource_id      = var.web_vmss_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog.id
}

resource "azurerm_monitor_data_collection_rule_association" "api" {
  name                    = "dcra-api"
  target_resource_id      = var.api_vmss_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog.id
}
