# modules/management/variables.tf

variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "hub_vnet_id" {
  type = string
}
variable "jumpbox_subnet_id" {
  type = string
}

#Login creds and LAN IP for jumpbox to bootstrap firewall
variable "nva_username" {
  type = string
}
variable "nva_password" {
  type = string
}
variable "nva_lan_ip" {
  type = string
}