# modules/nva/outputs.tf

output "nva_lan_ip" {
  description = "The Private IP of the LAN interface."
  value       = azurerm_network_interface.lan_nic.private_ip_address
}

output "nva_id" {
  description = "The ID of the NVA (for monitoring)."
  value       = azurerm_linux_virtual_machine.nva.id
}