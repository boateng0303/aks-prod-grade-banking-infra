# =============================================================================
# PRODUCTION ENVIRONMENT - OUTPUTS
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = module.aks.private_fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.login_server
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.vault_uri
}

output "keyvault_id" {
  description = "Key Vault ID"
  value       = module.keyvault.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "recovery_vault_id" {
  description = "Recovery Services Vault ID"
  value       = azurerm_recovery_services_vault.main.id
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.networking.vnet_id
}

output "get_credentials_command" {
  description = "Command to get AKS credentials (requires private connectivity)"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.cluster_name}"
}
