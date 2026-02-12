# =============================================================================
# RESOURCE GROUP VARIABLES
# =============================================================================

variable "name" {
  description = "Name of the resource group"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,90}$", var.name))
    error_message = "Resource group name must be 1-90 characters and can only contain alphanumeric, hyphens, and underscores."
  }
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
  default     = "East US 2"
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}

variable "enable_delete_lock" {
  description = "Enable delete lock on the resource group"
  type        = bool
  default     = false
}
