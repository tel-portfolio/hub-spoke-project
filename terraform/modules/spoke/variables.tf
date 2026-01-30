# modules/spoke/variables.tf

variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}

variable "route_table_id" {
  description = "The ID of the Route Table to force traffic to the NVA."
  type        = string
}