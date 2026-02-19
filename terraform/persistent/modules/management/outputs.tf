# modules/management/outputs.tf

output "jumpbox_ip" {
  value = azurerm_network_interface.jumpbox_nic.private_ip_address
}