output "route_table_id" {
  description = "The ID of the Route Table."
  value       = azurerm_route_table.route_table_spoke.id
}