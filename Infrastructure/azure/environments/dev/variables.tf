# =============================================================================
# DEV ENVIRONMENT - VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "banking"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "development"
}

variable "owner_email" {
  description = "Owner email for tagging"
  type        = string
  default     = "devops@company.com"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "aks_admin_group_ids" {
  description = "Azure AD group IDs for AKS cluster admins"
  type        = list(string)
  default     = []
}

variable "keyvault_admin_object_ids" {
  description = "Object IDs for Key Vault administrators"
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

variable "alert_webhook_receivers" {
  description = "Webhook receivers for alerts (Slack, PagerDuty, etc.)"
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts (set via TF_VAR_slack_webhook_url or GitHub Secret)"
  type        = string
  default     = ""
  sensitive   = true
}
