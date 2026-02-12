# =============================================================================
# PRODUCTION ENVIRONMENT - VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "banking"
}

variable "location" {
  description = "Azure region for primary resources"
  type        = string
  default     = "eastus"
}

variable "cost_center" {
  description = "Cost center for billing and tagging"
  type        = string
  default     = "production"
}

variable "owner_email" {
  description = "Owner email for tagging and notifications"
  type        = string
  default     = "devops@company.com"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.32"
}

variable "aks_admin_group_ids" {
  description = "Azure AD group object IDs for AKS cluster administrators"
  type        = list(string)
  default     = []
}

variable "keyvault_admin_object_ids" {
  description = "Azure AD object IDs for Key Vault administrators"
  type        = list(string)
  default     = []
}

variable "alert_email_receivers" {
  description = "Email receivers for alerts"
  type = list(object({
    name  = string
    email = string
  }))
  default = []
}

variable "alert_sms_receivers" {
  description = "SMS receivers for critical alerts"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "alert_webhook_receivers" {
  description = "Webhook receivers for alerts (Slack, PagerDuty, etc.)"
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "acr_georeplications" {
  description = "Azure Container Registry geo-replication settings"
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, true)
    zone_redundancy_enabled   = optional(bool, true)
  }))
  default = [
    {
      location                  = "West US 2"  # Must differ from primary ACR location
      regional_endpoint_enabled = true
      zone_redundancy_enabled   = true
    }
  ]
}
