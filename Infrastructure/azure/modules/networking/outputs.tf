# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "database_subnet_id" {
  description = "The ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "appgw_subnet_id" {
  description = "The ID of the Application Gateway subnet"
  value       = try(azurerm_subnet.application_gateway[0].id, null)
}

output "private_endpoint_subnet_id" {
  description = "The ID of the Private Endpoint subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "mysql_private_dns_zone_id" {
  description = "The ID of the MySQL private DNS zone"
  value       = azurerm_private_dns_zone.mysql.id
}

output "mysql_dns_zone_link_id" {
  description = "The ID of the MySQL DNS zone VNet link (use as dependency)"
  value       = azurerm_private_dns_zone_virtual_network_link.mysql.id
}

output "keyvault_private_dns_zone_id" {
  description = "The ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.keyvault.id
}

output "acr_private_dns_zone_id" {
  description = "The ID of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.acr.id
}

output "sql_private_dns_zone_id" {
  description = "The ID of the SQL Server private DNS zone"
  value       = azurerm_private_dns_zone.sql.id
}

output "sql_dns_zone_link_id" {
  description = "The ID of the SQL DNS zone VNet link (use as dependency)"
  value       = azurerm_private_dns_zone_virtual_network_link.sql.id
}

output "nat_gateway_public_ip" {
  description = "The public IP of the NAT Gateway"
  value       = try(azurerm_public_ip.nat[0].ip_address, null)
}
