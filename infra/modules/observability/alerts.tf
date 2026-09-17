# Proactive alerting: a synthetic availability probe plus metric/log alerts on the
# edge, database, and backup job. Everything routes through one action group and is
# gated on alert_email so non-prod environments can opt out by leaving it unset.

locals {
  alerts_enabled = var.alert_email != ""
}

resource "azurerm_monitor_action_group" "main" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.short_prefix}-ag"
  resource_group_name = var.rg
  short_name          = "astalerts"
  tags                = var.tags

  email_receiver {
    name          = "ops"
    email_address = var.alert_email
  }
}

# Workspace-based Application Insights hosts the synthetic web test and its metrics.
resource "azurerm_application_insights" "main" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.short_prefix}-appi"
  resource_group_name = var.rg
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# Synthetic availability: multi-region GET of the edge /health endpoint over TLS.
resource "azurerm_application_insights_standard_web_test" "health" {
  count                   = local.alerts_enabled ? 1 : 0
  name                    = "${var.short_prefix}-webtest-health"
  resource_group_name     = var.rg
  location                = var.location
  application_insights_id = azurerm_application_insights.main[0].id
  description             = "Edge /health synthetic probe"
  enabled                 = true
  frequency               = 300
  timeout                 = 30
  retry_enabled           = true
  geo_locations           = ["us-il-ch1-azr", "us-ca-sjc-azr", "emea-nl-ams-azr"]
  tags                    = var.tags

  request {
    url = "https://${var.frontdoor_endpoint_host}/health"
  }

  validation_rules {
    expected_status_code = 200
    ssl_check_enabled    = true
  }
}

resource "azurerm_monitor_metric_alert" "availability" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.short_prefix}-alert-availability"
  resource_group_name = var.rg
  scopes              = [azurerm_application_insights.main[0].id]
  description         = "Edge availability dropped below 90% across probe locations."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 90

    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values   = [azurerm_application_insights_standard_web_test.health[0].name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

# Edge 5xx rate: sustained server errors surfaced by Front Door.
resource "azurerm_monitor_metric_alert" "frontdoor_5xx" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.short_prefix}-alert-edge-5xx"
  resource_group_name = var.rg
  scopes              = [var.frontdoor_profile_id]
  description         = "Front Door 5xx response rate exceeded 5%."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "Percentage5XX"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

# Database storage headroom (CPU is already covered by db_cpu in dashboard.tf).
resource "azurerm_monitor_metric_alert" "db_storage" {
  count               = local.alerts_enabled ? 1 : 0
  name                = "${var.short_prefix}-alert-db-storage"
  resource_group_name = var.rg
  scopes              = [var.db_id]
  description         = "Database storage above 85%."
  severity            = 2
  frequency           = "PT15M"
  window_size         = "PT30M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

# Backup freshness: the job logs "uploaded appdb/..." on every successful dump. No
# such line across the trailing 48h window (two 24h cycles) means the backup is
# failing or the runner is down. The wide window avoids false positives from the
# daily cadence drifting across a shorter window boundary.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_failure" {
  count                = local.alerts_enabled ? 1 : 0
  name                 = "${var.short_prefix}-alert-backup-stale"
  resource_group_name  = var.rg
  location             = var.location
  description          = "No successful database backup completed in the last 48 hours."
  severity             = 1
  scopes               = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT1H"
  window_duration      = "P2D"
  tags                 = var.tags

  criteria {
    # isfuzzy tolerates the ContainerInstanceLog_CL table not existing yet on a
    # fresh deploy (it is created only once the backup container first logs).
    query                   = <<-QUERY
      union isfuzzy=true ContainerInstanceLog_CL
      | where ContainerGroup_s == "${var.short_prefix}-backup"
      | where Message has "uploaded appdb/"
      | summarize successes = count()
    QUERY
    time_aggregation_method = "Total"
    metric_measure_column   = "successes"
    operator                = "LessThanOrEqual"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.main[0].id]
  }
}
