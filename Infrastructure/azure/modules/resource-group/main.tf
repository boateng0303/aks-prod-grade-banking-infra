# =============================================================================
# AZURE RESOURCE GROUP MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Management Lock (Optional - for production)
# -----------------------------------------------------------------------------

resource "azurerm_management_lock" "rg_lock" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${var.name}-delete-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group cannot be deleted"
}
