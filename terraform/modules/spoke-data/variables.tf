# modules/spoke-data/variables.tf

variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "lan_subnet_id" {
  type = string
}
variable "spoke_compute_subnet_id" {
  type = string
}