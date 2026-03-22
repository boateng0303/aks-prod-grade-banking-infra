# =============================================================================
# AZURE KEY VAULT MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = var.sku_name

  # Security settings
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Network settings
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.network_acls_default_action
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      network_acls[0].ip_rules,
      network_acls[0].virtual_network_subnet_ids,
    ]
  }
}

# -----------------------------------------------------------------------------
# Access Policies (if not using RBAC)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_rbac_authorization ? 0 : 1

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
  ]
}

resource "azurerm_key_vault_access_policy" "aks" {
  count = var.enable_rbac_authorization ? 0 : (var.aks_identity_object_id != null ? 1 : 0)

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.aks_identity_object_id

  secret_permissions = [
    "Get", "List"
  ]

  certificate_permissions = [
    "Get", "List"
  ]
}

# -----------------------------------------------------------------------------
# RBAC Role Assignments (if using RBAC)
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "terraform_admin" {
  count = var.enable_rbac_authorization ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_secrets_user" {
  count = var.enable_rbac_authorization && var.aks_identity_object_id != null ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_identity_object_id
}

resource "azurerm_role_assignment" "additional_admins" {
  for_each = var.enable_rbac_authorization ? toset(var.admin_object_ids) : []

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "secrets_readers" {
  for_each = var.enable_rbac_authorization ? toset(var.secrets_reader_object_ids) : []

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "keyvault" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Diagnostic Settings Cleanup (prevents orphaned resource conflicts)
# -----------------------------------------------------------------------------

resource "null_resource" "cleanup_keyvault_diagnostics" {
  count = var.enable_diagnostics ? 1 : 0

  triggers = {
    keyvault_id     = azurerm_key_vault.main.id
    diagnostic_name = "${var.name}-diagnostics"
  }

  provisioner "local-exec" {
    command     = "az monitor diagnostic-settings delete --resource ${azurerm_key_vault.main.id} --name ${var.name}-diagnostics 2>/dev/null || true"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }

  depends_on = [azurerm_key_vault.main]
}

# -----------------------------------------------------------------------------
# Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    azurerm_key_vault.main,
    null_resource.cleanup_keyvault_diagnostics
  ]
}
