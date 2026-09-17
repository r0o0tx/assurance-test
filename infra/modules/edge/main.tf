resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.short_prefix}-fd"
  resource_group_name = var.rg
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.short_prefix}-ep-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = var.tags
}

# -------- Origin groups (one per tier), health-probed on /health --------
resource "azurerm_cdn_frontdoor_origin_group" "web" {
  name                     = "og-web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    interval_in_seconds = 30
    path                = "/health"
    protocol            = "Http"
    request_type        = "GET"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "api" {
  name                     = "og-api"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    interval_in_seconds = 30
    path                = "/health"
    protocol            = "Http"
    request_type        = "GET"
  }
}

# -------- Origins (the tier load balancer public FQDNs) --------
resource "azurerm_cdn_frontdoor_origin" "web" {
  name                           = "origin-web"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.web.id
  enabled                        = true
  host_name                      = var.web_origin_host
  origin_host_header             = var.web_origin_host
  http_port                      = var.app_port
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  private_link {
    request_message        = "front door origin access"
    location               = var.location
    private_link_target_id = var.web_pls_id
  }
}

resource "azurerm_cdn_frontdoor_origin" "api" {
  name                           = "origin-api"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.api.id
  enabled                        = true
  host_name                      = var.api_origin_host
  origin_host_header             = var.api_origin_host
  http_port                      = var.app_port
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  private_link {
    request_message        = "front door origin access"
    location               = var.location
    private_link_target_id = var.api_pls_id
  }
}

# -------- Rule set: keep the dynamic web paths uncached --------
resource "azurerm_cdn_frontdoor_rule_set" "web" {
  name                     = "webrules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_rule" "bypass_dynamic" {
  name                      = "bypassdynamic"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.web.id
  order                     = 1

  actions {
    route_configuration_override_action {
      cache_behavior = "Disabled"
    }
  }

  conditions {
    url_path_condition {
      operator     = "Equal"
      match_values = ["/", "health", "/health"]
    }
  }
}

# Force edge caching of static assets so they return cache HITs regardless of the
# origin's cache-control (Express serves them with max-age=0).
resource "azurerm_cdn_frontdoor_rule" "cache_static" {
  name                      = "cachestatic"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.web.id
  order                     = 2

  actions {
    route_configuration_override_action {
      cache_behavior                = "OverrideAlways"
      cache_duration                = "1.00:00:00"
      query_string_caching_behavior = "IgnoreQueryString"
      compression_enabled           = true
    }
  }

  conditions {
    url_file_extension_condition {
      operator     = "Equal"
      match_values = ["css", "js", "gif", "png", "jpg", "jpeg", "svg", "ico", "woff", "woff2"]
    }
  }
}

# -------- Routes: /api/* to api (no cache), /* to web (cache static) --------
resource "azurerm_cdn_frontdoor_route" "api" {
  name                          = "route-api"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.api.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/api/*"]
  forwarding_protocol           = "HttpOnly"
  https_redirect_enabled        = true
  link_to_default_domain        = true
}

resource "azurerm_cdn_frontdoor_route" "web" {
  name                          = "route-web"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.web.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.web.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpOnly"
  https_redirect_enabled        = true
  link_to_default_domain        = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress = [
      "text/html",
      "text/css",
      "application/javascript",
      "image/svg+xml",
      "application/json",
      "text/plain",
    ]
  }
}

# -------- WAF (Standard tier: custom rules) + endpoint association --------
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                = "${var.short_prefix}waf"
  resource_group_name = var.rg
  sku_name            = "Premium_AzureFrontDoor"
  enabled             = true
  mode                = "Prevention"

  custom_rule {
    name                           = "ratelimit"
    enabled                        = true
    priority                       = 1
    type                           = "RateLimitRule"
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 300
    action                         = "Block"

    match_condition {
      match_variable = "RequestUri"
      operator       = "Contains"
      match_values   = ["/"]
    }
  }

  # Managed rulesets (Premium tier): OWASP core protection + bot mitigation.
  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "${var.short_prefix}-secpol"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
