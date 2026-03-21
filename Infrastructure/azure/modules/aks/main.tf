# =============================================================================
# AZURE KUBERNETES SERVICE (AKS) MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

# -----------------------------------------------------------------------------
# DATA
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# USER ASSIGNED IDENTITY
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# AKS CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  node_resource_group = "${var.cluster_name}-nodes-rg"

  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null

  automatic_channel_upgrade = var.automatic_channel_upgrade

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool_vm_size
    node_count                   = var.system_node_pool_count
    min_count                    = var.system_node_pool_min_count
    max_count                    = var.system_node_pool_max_count
    enable_auto_scaling          = var.enable_auto_scaling
    max_pods                     = var.max_pods_per_node
    os_disk_size_gb              = var.os_disk_size_gb
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true
    zones                        = var.availability_zones

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = {
      nodepool    = "system"
      environment = var.environment
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = var.enable_azure_rbac
    admin_group_object_ids = var.admin_group_object_ids
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = var.enable_workload_identity

  azure_policy_enabled = var.enable_azure_policy

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  dynamic "microsoft_defender" {
    for_each = var.sku_tier != "Free" && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].zones,
      kubernetes_version,
    ]
  }
}

# -----------------------------------------------------------------------------
# USER NODE POOL
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.enable_user_node_pool ? 1 : 0

  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_count
  min_count             = var.user_node_pool_min_count
  max_count             = var.user_node_pool_max_count
  enable_auto_scaling   = var.enable_auto_scaling
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = var.os_disk_size_gb
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  mode                  = "User"

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    nodepool    = "user"
    environment = var.environment
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count,
      zones,
    ]
  }
}

# -----------------------------------------------------------------------------
# SPOT NODE POOL
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.enable_spot_node_pool ? 1 : 0

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.spot_node_pool_vm_size
  min_count             = 0
  max_count             = var.spot_node_pool_max_count
  enable_auto_scaling   = true
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = var.os_disk_size_gb
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = var.spot_max_price

  node_labels = {
    nodepool = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.enable_acr_pull ? 1 : 0

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.main]
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS (ORDER FIXED)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-audit" }
  enabled_log { category = "kube-audit-admin" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}
