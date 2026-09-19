# Promote the dba group to the server's Entra administrator, so database access
# is granted by group membership rather than a shared password.
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "dba" {
  server_name         = var.db_server_name
  resource_group_name = var.rg_name
  tenant_id           = var.tenant_id
  object_id           = azuread_group.role["dba"].object_id
  principal_name      = azuread_group.role["dba"].display_name
  principal_type      = "Group"
}
