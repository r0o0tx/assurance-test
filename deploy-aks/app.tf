# Deploy the application chart to the cluster.
resource "helm_release" "app" {
  name  = "assurance-test"
  chart = "${path.module}/chart"

  # Skip fetching the cluster's full OpenAPI schema for client-side validation;
  # the manifests are plain Deployments and Services, and the schema download is
  # unreliable over some networks.
  disable_openapi_validation = true

  set {
    name  = "registry"
    value = data.azurerm_container_registry.shared.login_server
  }
  set {
    name  = "webTag"
    value = var.web_tag
  }
  set {
    name  = "apiTag"
    value = var.api_tag
  }
  set {
    name  = "db.host"
    value = azurerm_postgresql_flexible_server.db.fqdn
  }
  set_sensitive {
    name  = "db.password"
    value = random_password.db.result
  }

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_role_assignment.aks_acr,
    azurerm_postgresql_flexible_server_database.app,
  ]
}
