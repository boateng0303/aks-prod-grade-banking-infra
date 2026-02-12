# =============================================================================
# AZURE CONTAINER REGISTRY MODULE
# =============================================================================

# ---------------------------------------------------------------------------
# Container Registry
# ---------------------------------------------------------------------------

resource "azurerm_container_registry" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  zone_redundancy_enabled = var.sku == "Premium" ? var.zone_redundancy_enabled : false
  anonymous_pull_enabled = false
  data_endpoint_enabled  = var.sku == "Premium" ? var.data_endpoint_enabled : false

  # Network rules (Premium only)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && !var.public_network_access_enabled ? [1] : []
    content {
      default_action = "Deny"
    }
  }

  # Retention policy (Premium only)
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      days    = var.retention_days
      enabled = true
    }
  }

  # Trust policy (Premium only)
  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.enable_content_trust ? [1] : []
    content {
      enabled = true
    }
  }

  quarantine_policy_enabled = var.sku == "Premium" ? var.quarantine_policy_enabled : false

  # Encryption (Premium only)
  dynamic "encryption" {
    for_each = var.sku == "Premium" && var.encryption_key_id != null ? [1] : []
    content {
      enabled            = true
      key_vault_key_id   = var.encryption_key_id
      identity_client_id = var.encryption_identity_client_id
    }
  }

  # Geo-replications (Premium only)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = var.tags
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Private Endpoint
# ---------------------------------------------------------------------------

resource "azurerm_private_endpoint" "acr" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  depends_on = [
    azurerm_container_registry.main
  ]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Scope Maps
# ---------------------------------------------------------------------------

resource "azurerm_container_registry_scope_map" "pull" {
  count = var.create_pull_scope_map ? 1 : 0

  name                    = "pull-scope"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/*/content/read",
    "repositories/*/metadata/read"
  ]

  depends_on = [azurerm_container_registry.main]
}

resource "azurerm_container_registry_scope_map" "push" {
  count = var.create_push_scope_map ? 1 : 0

  name                    = "push-scope"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read",
    "repositories/*/metadata/write"
  ]

  depends_on = [azurerm_container_registry.main]
}

# ---------------------------------------------------------------------------
# Webhooks
# ---------------------------------------------------------------------------

resource "azurerm_container_registry_webhook" "main" {
  for_each = var.webhooks

  name                = each.key
  registry_name       = azurerm_container_registry.main.name
  resource_group_name = var.resource_group_name
  location            = var.location

  service_uri = each.value.service_uri
  actions     = each.value.actions
  status      = each.value.enabled ? "enabled" : "disabled"
  scope       = each.value.scope

  custom_headers = each.value.custom_headers

  depends_on = [azurerm_container_registry.main]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Diagnostic Settings
# ---------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "acr" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    azurerm_container_registry.main
  ]
}
