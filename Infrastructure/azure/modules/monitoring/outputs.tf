# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_primary_key" {
  description = "Primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_secondary_key" {
  description = "Secondary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "application_insights_id" {
  description = "The ID of Application Insights"
  value       = try(azurerm_application_insights.main[0].id, null)
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = try(azurerm_application_insights.main[0].instrumentation_key, null)
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = try(azurerm_application_insights.main[0].connection_string, null)
  sensitive   = true
}

output "critical_action_group_id" {
  description = "ID of the critical alert action group"
  value       = azurerm_monitor_action_group.critical.id
}

output "warning_action_group_id" {
  description = "ID of the warning alert action group"
  value       = azurerm_monitor_action_group.warning.id
}
