# =============================================================================
# ACR OUTPUTS
# =============================================================================

output "id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "The login server URL"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "Admin username (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "Admin password (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address : null
}
