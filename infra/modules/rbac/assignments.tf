# Built-in role assignments for the groups that map cleanly to an Azure role.
resource "azurerm_role_assignment" "builtin" {
  for_each             = { for slug, cfg in local.role_groups : slug => cfg if cfg.builtin_role != null }
  scope                = var.rg_id
  role_definition_name = each.value.builtin_role
  principal_id         = azuread_group.role[each.key].object_id
}

# Security reviewers also get plain Reader so posture data resolves resource details.
resource "azurerm_role_assignment" "security_reader" {
  scope                = var.rg_id
  role_definition_name = "Reader"
  principal_id         = azuread_group.role["security"].object_id
}

# Custom-role groups.
resource "azurerm_role_assignment" "app_operator" {
  scope              = var.rg_id
  role_definition_id = azurerm_role_definition.app_operator.role_definition_resource_id
  principal_id       = azuread_group.role["dev"].object_id
}

resource "azurerm_role_assignment" "db_operator" {
  scope              = var.rg_id
  role_definition_id = azurerm_role_definition.db_operator.role_definition_resource_id
  principal_id       = azuread_group.role["dba"].object_id
}
