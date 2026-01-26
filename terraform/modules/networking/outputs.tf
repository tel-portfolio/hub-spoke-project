# modules/networking/outputs.tf

output "wan_subnet_id" {
  description = "WAN subnet ID."
  value       = azurerm_subnet.wan_subnet.id
}

output "lan_subnet_id" {
  description = "LAN subnet ID."
  value       = azurerm_subnet.lan_subnet.id
}

output "jumpbox_subnet_id" {
  description = "Bastion subnet ID."
  value       = azurerm_subnet.jumpbox_subnet.id
}