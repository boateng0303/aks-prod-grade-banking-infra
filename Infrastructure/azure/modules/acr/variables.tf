# =============================================================================
# ACR VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the Container Registry (alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU tier (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

# Security
variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy (Premium only)"
  type        = bool
  default     = true
}

variable "data_endpoint_enabled" {
  description = "Enable data endpoints (Premium only)"
  type        = bool
  default     = true
}

variable "enable_content_trust" {
  description = "Enable content trust (Premium only)"
  type        = bool
  default     = true
}

variable "quarantine_policy_enabled" {
  description = "Enable quarantine policy (Premium only)"
  type        = bool
  default     = false
}

# Network
variable "allowed_ip_ranges" {
  description = "Allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Allowed subnet IDs"
  type        = list(string)
  default     = []
}

# Private Endpoint
variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

# Retention
variable "retention_days" {
  description = "Untagged manifest retention days (Premium only)"
  type        = number
  default     = 30
}

# Encryption
variable "encryption_key_id" {
  description = "Key Vault key ID for encryption (Premium only)"
  type        = string
  default     = null
}

variable "encryption_identity_client_id" {
  description = "Identity client ID for encryption"
  type        = string
  default     = null
}

# Geo-replication
variable "georeplications" {
  description = "Geo-replication settings (Premium only)"
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, true)
    zone_redundancy_enabled   = optional(bool, true)
  }))
  default = []
}

# Scope Maps
variable "create_pull_scope_map" {
  description = "Create a pull scope map"
  type        = bool
  default     = false
}

variable "create_push_scope_map" {
  description = "Create a push scope map"
  type        = bool
  default     = false
}

# Webhooks
variable "webhooks" {
  description = "Map of webhooks to create"
  type = map(object({
    service_uri    = string
    actions        = list(string)
    enabled        = optional(bool, true)
    scope          = optional(string, "")
    custom_headers = optional(map(string), {})
  }))
  default = {}
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
