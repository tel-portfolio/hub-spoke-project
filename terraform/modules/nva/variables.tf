# modules/nva/variabled.tf

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}
variable "admin_username" {
  description = "The admin username for the NVA"
  type        = string
  default     = "twoolsey"
}
variable "wan_subnet_id" {
  description = "The ID of the Untrust Subnet"
  type        = string
}

variable "lan_subnet_id" {
  description = "The ID of the Trust Subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}