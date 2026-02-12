# =============================================================================
# MONITORING VARIABLES
# =============================================================================

variable "prefix" {
  description = "Prefix for resource names"
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

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# Log Analytics
variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "log_analytics_sku" {
  description = "SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days"
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily data ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "reservation_capacity" {
  description = "Capacity reservation in GB/day (for CapacityReservation SKU)"
  type        = number
  default     = null
}

# Solutions
variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = true
}

variable "enable_security_insights" {
  description = "Enable Security Insights (Sentinel) solution"
  type        = bool
  default     = false
}

# Application Insights
variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = true
}

variable "app_insights_name" {
  description = "Name of Application Insights"
  type        = string
  default     = ""
}

variable "app_insights_type" {
  description = "Application type for App Insights"
  type        = string
  default     = "web"
}

variable "app_insights_retention_days" {
  description = "Application Insights retention in days"
  type        = number
  default     = 90
}

variable "app_insights_daily_cap_gb" {
  description = "Daily data cap for App Insights in GB"
  type        = number
  default     = 10
}

variable "app_insights_sampling_percentage" {
  description = "Sampling percentage for App Insights"
  type        = number
  default     = 100
}

# Alert Receivers
variable "alert_email_receivers" {
  description = "Email receivers for alerts"
  type = list(object({
    name  = string
    email = string
  }))
  default = []
}

variable "alert_sms_receivers" {
  description = "SMS receivers for alerts"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "alert_webhook_receivers" {
  description = "Webhook receivers for alerts"
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

# Resource IDs for alerts
variable "aks_cluster_id" {
  description = "AKS cluster ID for metric alerts"
  type        = string
  default     = null
}

variable "mysql_server_id" {
  description = "MySQL server ID for metric alerts"
  type        = string
  default     = null
}

variable "enable_aks_alerts" {
  description = "Enable AKS metric alerts"
  type        = bool
  default     = false
}

variable "enable_mysql_alerts" {
  description = "Enable MySQL metric alerts"
  type        = bool
  default     = false
}

# Dashboard
variable "create_dashboard" {
  description = "Create Azure Portal dashboard"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
