# =============================================================================
# DEV ENVIRONMENT - TERRAFORM BACKEND
# =============================================================================

terraform {
  backend "azurerm" {
    # These values are provided via -backend-config in CI/CD
    # resource_group_name  = "tfstate-rg"
    # storage_account_name = "tfstate6bc89fe2"
    # container_name       = "tfstate"
    # key                  = "dev/terraform.tfstate"
    
    # Enable state locking
    use_oidc = true
  }
}
