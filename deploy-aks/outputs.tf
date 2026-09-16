output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "resource_group" {
  value = azurerm_resource_group.aks.name
}

output "get_credentials_cmd" {
  value = "az aks get-credentials -g ${azurerm_resource_group.aks.name} -n ${azurerm_kubernetes_cluster.main.name}"
}
