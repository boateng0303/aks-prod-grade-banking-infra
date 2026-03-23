# =============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

# -----------------------------------------------------------------------------
# Random Suffix for Global Names
# -----------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  environment = "dev"
  prefix      = "${var.project_name}-${local.environment}"
  location    = var.location

  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner_email
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name               = "${local.prefix}-rg"
  location           = local.location
  enable_delete_lock = false
  tags               = local.common_tags
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = module.resource_group.name
  vnet_name           = "${local.prefix}-vnet"

  address_space                = ["10.0.0.0/16"]
  aks_subnet_cidr              = "10.0.0.0/22"
  database_subnet_cidr         = "10.0.4.0/24"
  appgw_subnet_cidr            = "10.0.5.0/24"
  private_endpoint_subnet_cidr = "10.0.6.0/24"
  bastion_subnet_cidr          = "10.0.7.0/26"

  enable_application_gateway = true
  enable_nat_gateway         = false # Disabled to stay within 3 public IP quota
  enable_bastion             = false

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = module.resource_group.name
  subscription_id     = data.azurerm_subscription.current.subscription_id

  log_analytics_name = "${local.prefix}-law"
  retention_in_days  = 30

  enable_container_insights   = true
  enable_security_insights    = false
  enable_application_insights = true
  app_insights_name           = "${local.prefix}-ai"

  alert_email_receivers = var.alert_email_receivers

  alert_sms_receivers = var.alert_sms_receivers

  alert_webhook_receivers = concat(
    var.alert_webhook_receivers,
    var.slack_webhook_url != "" ? [{
      name        = "slack-alerts"
      service_uri = var.slack_webhook_url
    }] : []
  )

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Azure Container Registry
# -----------------------------------------------------------------------------

module "acr" {
  source = "../../modules/acr"

  name                = replace("${var.project_name}${local.environment}${random_string.suffix.result}acr", "-", "")
  location            = local.location
  resource_group_name = module.resource_group.name

  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false

  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.acr_private_dns_zone_id

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

module "keyvault" {
  source = "../../modules/keyvault"

  name                = "${var.project_name}-${local.environment}-kv-${random_string.suffix.result}"
  location            = local.location
  resource_group_name = module.resource_group.name

  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  public_network_access_enabled = false
  network_acls_default_action   = "Deny"

  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.keyvault_private_dns_zone_id

  admin_object_ids = var.keyvault_admin_object_ids

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

module "aks" {
  source = "../../modules/aks"

  cluster_name        = "${local.prefix}-aks"
  location            = local.location
  resource_group_name = module.resource_group.name
  dns_prefix          = "${var.project_name}-${local.environment}"
  kubernetes_version  = var.kubernetes_version
  environment         = local.environment

  subnet_id = module.networking.aks_subnet_id

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true
  sku_tier                            = "Free"

  system_node_pool_vm_size   = "Standard_DC2s_v3"
  system_node_pool_count     = 1
  system_node_pool_min_count = 1
  system_node_pool_max_count = 3

  enable_user_node_pool = false # Disabled to save vCPUs

  enable_spot_node_pool = false
  availability_zones    = []

  enable_azure_rbac      = true
  admin_group_object_ids = var.aks_admin_group_ids

  enable_workload_identity = true
  enable_azure_policy      = false

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# NOTE: SQL Database will be created via Azure Portal (ClickOps)
# Due to subscription provisioning restrictions in Terraform
# -----------------------------------------------------------------------------
