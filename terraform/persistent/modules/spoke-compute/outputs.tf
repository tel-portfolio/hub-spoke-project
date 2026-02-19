#modules/spoke/outputs.tf

output "vnet_id" {
  value = azurerm_virtual_network.algo_spoke.id
}
output "vnet_name" {
  value = azurerm_virtual_network.algo_spoke.name
}
output "subnet_id" {
  value = azurerm_subnet.algo_workload.id
}