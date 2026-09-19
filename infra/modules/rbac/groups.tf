locals {
  # One Entra group per operating role. builtin_role names a built-in Azure
  # role assigned at the resource group; roles left null are granted a scoped
  # custom role defined in roles.tf instead.
  role_groups = {
    readonly = {
      description  = "Read-only visibility into the environment."
      builtin_role = "Reader"
    }
    dev = {
      description  = "Application operators: inspect and restart the app tiers, read logs."
      builtin_role = null # astst custom app-operator role
    }
    ops = {
      description  = "Environment operators: manage the environment's resources."
      builtin_role = "Contributor"
    }
    dba = {
      description  = "Database operators: manage the PostgreSQL server and its config."
      builtin_role = null # astst custom db-operator role + Entra DB admin
    }
    security = {
      description  = "Security reviewers: read security posture and audit data."
      builtin_role = "Security Reader"
    }
  }
}

resource "azuread_group" "role" {
  for_each         = local.role_groups
  display_name     = "${var.short_prefix}-${var.environment}-${each.key}"
  description      = each.value.description
  security_enabled = true
}
