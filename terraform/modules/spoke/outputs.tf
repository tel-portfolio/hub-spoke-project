#modules/spoke/outputs.tf

output "vnet_id" {
  value = azurerm_virtual_network.spoke.id
}
output "vnet_name" {
  value = azurerm_virtual_network.spoke.name
}
output "subnet_id" {
  value = azurerm_subnet.workload.id
}