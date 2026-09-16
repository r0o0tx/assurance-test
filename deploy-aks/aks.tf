# Reuse the shared registry that already holds the web/api images.
data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.prefix}-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  dns_prefix          = "${var.prefix}aks"
  tags                = var.tags

  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    node_count          = var.node_count
    min_count           = 2
    max_count           = 4
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
  }
}

# Cluster can pull from the shared registry.
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = data.azurerm_container_registry.shared.id
  skip_service_principal_aad_check = true
}
