# =============================================================================
# NETWORKING VARIABLES
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

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers (leave empty for Azure default)"
  type        = list(string)
  default     = []
}

variable "aks_subnet_cidr" {
  description = "CIDR for AKS subnet"
  type        = string
  default     = "10.0.0.0/22"
}

variable "database_subnet_cidr" {
  description = "CIDR for database subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "appgw_subnet_cidr" {
  description = "CIDR for Application Gateway subnet"
  type        = string
  default     = "10.0.5.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR for Private Endpoints subnet"
  type        = string
  default     = "10.0.6.0/24"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for Azure Bastion subnet"
  type        = string
  default     = "10.0.7.0/26"
}

variable "enable_application_gateway" {
  description = "Enable Application Gateway subnet"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound traffic"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
