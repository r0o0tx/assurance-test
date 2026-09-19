# Least-privilege custom roles scoped to this resource group only.

resource "azurerm_role_definition" "app_operator" {
  name        = "${var.short_prefix}-${var.environment}-app-operator"
  scope       = var.rg_id
  description = "Inspect and restart the application scale sets and read their logs, without contributor rights."

  permissions {
    actions = [
      "*/read",
      "Microsoft.Compute/virtualMachineScaleSets/restart/action",
      "Microsoft.Compute/virtualMachineScaleSets/start/action",
      "Microsoft.Compute/virtualMachineScaleSets/manualUpgrade/action",
    ]
    data_actions = [
      "Microsoft.OperationalInsights/workspaces/query/*/read",
    ]
    not_actions      = []
    not_data_actions = []
  }

  assignable_scopes = [var.rg_id]
}

resource "azurerm_role_definition" "db_operator" {
  name        = "${var.short_prefix}-${var.environment}-db-operator"
  scope       = var.rg_id
  description = "Manage the PostgreSQL flexible server (restart, start/stop, server parameters) without contributor rights."

  permissions {
    actions = [
      "*/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/restart/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/start/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/stop/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/configurations/write",
    ]
    not_actions      = []
    not_data_actions = []
  }

  assignable_scopes = [var.rg_id]
}
