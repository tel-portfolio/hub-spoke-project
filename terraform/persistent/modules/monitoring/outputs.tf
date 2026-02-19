# modules/monitoring/outputs.tf

output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}
