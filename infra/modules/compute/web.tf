data "azurerm_client_config" "current" {}

# -------- Web load balancer: internal frontend, exposed to Front Door via a
# Private Link Service so the origin is never reachable from the public internet.
resource "azurerm_lb" "web" {
  name                = "${var.short_prefix}-web-lb"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "internal"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.web_internal_ip
    zones                         = ["1", "2", "3"]
  }
}

resource "azurerm_private_link_service" "web" {
  name                = "${var.short_prefix}-web-pls"
  resource_group_name = var.rg
  location            = var.location
  tags                = var.tags

  visibility_subscription_ids                 = [data.azurerm_client_config.current.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.web.frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name                       = "primary"
    subnet_id                  = var.pls_subnet_id
    private_ip_address_version = "IPv4"
    primary                    = true
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "bepool-web"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "web" {
  name                = "probe-web"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = var.app_port
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "web_internal" {
  name                           = "rule-web-internal"
  loadbalancer_id                = azurerm_lb.web.id
  frontend_ip_configuration_name = "internal"
  protocol                       = "Tcp"
  frontend_port                  = var.app_port
  backend_port                   = var.app_port
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web.id
}

# -------- Web scale set --------
resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                            = "${var.short_prefix}-web-vmss"
  resource_group_name             = var.rg
  location                        = var.location
  sku                             = var.vm_sku
  instances                       = var.web_instance_count
  zones                           = ["1", "2"]
  zone_balance                    = true
  admin_username                  = "azureuser"
  upgrade_mode                    = "Rolling"
  disable_password_authentication = true

  custom_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", {
    tier               = "web"
    image_tag          = var.web_image_tag
    acr_login_server   = var.acr_login_server
    acr_name           = var.acr_name
    identity_client_id = var.identity_client_id
    key_vault_name     = var.key_vault_name
    secret_names       = []
    extra_env          = "echo 'API_HOST=http://${var.api_internal_ip}:${var.app_port}' >> $ENVFILE"
  }))

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  network_interface {
    name    = "nic-web"
    primary = true
    ip_configuration {
      name                                   = "ipcfg"
      primary                                = true
      subnet_id                              = var.web_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web.id]
    }
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  extension {
    name                      = "health"
    publisher                 = "Microsoft.ManagedServices"
    type                      = "ApplicationHealthLinux"
    type_handler_version      = "1.0"
    automatic_upgrade_enabled = true
    settings                  = jsonencode({ protocol = "http", port = 3000, requestPath = "/health" })
  }

  extension {
    name                      = "ama"
    publisher                 = "Microsoft.Azure.Monitor"
    type                      = "AzureMonitorLinuxAgent"
    type_handler_version      = "1.29"
    automatic_upgrade_enabled = true
    settings = jsonencode({
      authentication = {
        managedIdentity = {
          "identifier-name"  = "mi_res_id"
          "identifier-value" = var.identity_id
        }
      }
    })
  }

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
  }

  rolling_upgrade_policy {
    max_batch_instance_percent              = 50
    max_unhealthy_instance_percent          = 50
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT30S"
  }

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "web" {
  name                = "${var.short_prefix}-web-autoscale"
  resource_group_name = var.rg
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web.id
  tags                = var.tags

  profile {
    name = "default"
    capacity {
      default = var.web_instance_count
      minimum = 2
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }
}
