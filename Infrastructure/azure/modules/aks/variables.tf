# =============================================================================
# AKS VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

# Private Cluster
variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = null
}

# SKU and Upgrades
variable "sku_tier" {
  description = "SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Free, Standard, or Premium."
  }
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (none, patch, rapid, stable, node-image)"
  type        = string
  default     = "stable"
}

# System Node Pool
variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_pool_count" {
  description = "Initial node count for system pool"
  type        = number
  default     = 2
}

variable "system_node_pool_min_count" {
  description = "Minimum node count for system pool"
  type        = number
  default     = 2
}

variable "system_node_pool_max_count" {
  description = "Maximum node count for system pool"
  type        = number
  default     = 5
}

# User Node Pool
variable "enable_user_node_pool" {
  description = "Enable user node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_pool_count" {
  description = "Initial node count for user pool"
  type        = number
  default     = 2
}

variable "user_node_pool_min_count" {
  description = "Minimum node count for user pool"
  type        = number
  default     = 2
}

variable "user_node_pool_max_count" {
  description = "Maximum node count for user pool"
  type        = number
  default     = 10
}

# Spot Node Pool
variable "enable_spot_node_pool" {
  description = "Enable spot node pool"
  type        = bool
  default     = false
}

variable "spot_node_pool_vm_size" {
  description = "VM size for spot node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "spot_node_pool_max_count" {
  description = "Maximum node count for spot pool"
  type        = number
  default     = 10
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (-1 for on-demand price)"
  type        = number
  default     = -1
}

# Node Pool Common
variable "enable_auto_scaling" {
  description = "Enable cluster auto-scaling"
  type        = bool
  default     = true
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 50
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# Network
variable "network_plugin" {
  description = "Network plugin (azure, kubenet, none)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure, calico, cilium)"
  type        = string
  default     = "azure"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.100.0.10"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.100.0.0/16"
}

variable "outbound_type" {
  description = "Outbound type (loadBalancer, userDefinedRouting, managedNATGateway)"
  type        = string
  default     = "loadBalancer"
}

variable "outbound_ip_count" {
  description = "Number of outbound IPs for load balancer"
  type        = number
  default     = 1
}

# Azure AD & RBAC
variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admins"
  type        = list(string)
  default     = []
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

# Add-ons
variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "acr_id" {
  description = "Azure Container Registry ID for pull access"
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "enable_acr_pull" {
  description = "Enable ACR pull role assignment"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
