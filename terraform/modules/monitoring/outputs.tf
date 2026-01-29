# modules/monitoring/outputs.tf

output "workspace_id" {
    value = azurerm_log_analytics_workspace.law.id
}

output "workspace_key" {
  value     = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive = true
}