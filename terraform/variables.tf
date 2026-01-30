# Root variables.tf

variable "location" {
  description = "Azure region where resource located."
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  type    = string
  default = "rg-hub-spoke-portfolio"
}