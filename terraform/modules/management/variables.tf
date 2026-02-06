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