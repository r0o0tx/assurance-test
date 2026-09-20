resource "azurerm_portal_dashboard" "main" {
  name                = "${var.short_prefix}-dashboard"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  dashboard_properties = templatefile("${path.module}/dashboard.tftpl", {
    fd_id       = var.frontdoor_profile_id
    web_vmss_id = var.web_vmss_id
    api_vmss_id = var.api_vmss_id
    db_id       = var.db_id
  })
}

resource "azurerm_monitor_metric_alert" "web_cpu" {
  name                = "${var.short_prefix}-web-cpu-high"
  resource_group_name = var.rg
  scopes              = [var.web_vmss_id]
  description         = "Web tier average CPU is high."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  dynamic "action" {
    for_each = azurerm_monitor_action_group.main[*].id
    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "api_cpu" {
  name                = "${var.short_prefix}-api-cpu-high"
  resource_group_name = var.rg
  scopes              = [var.api_vmss_id]
  description         = "API tier average CPU is high."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  dynamic "action" {
    for_each = azurerm_monitor_action_group.main[*].id
    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "db_cpu" {
  name                = "${var.short_prefix}-db-cpu-high"
  resource_group_name = var.rg
  scopes              = [var.db_id]
  description         = "Database average CPU is high."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  dynamic "action" {
    for_each = azurerm_monitor_action_group.main[*].id
    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "fd_latency" {
  name                = "${var.short_prefix}-fd-latency-high"
  resource_group_name = var.rg
  scopes              = [var.frontdoor_profile_id]
  description         = "Front Door total latency is high."
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  dynamic "action" {
    for_each = azurerm_monitor_action_group.main[*].id
    content {
      action_group_id = action.value
    }
  }
}
