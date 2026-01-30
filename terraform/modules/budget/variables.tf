# modules/budget/variables.tf

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type        = string
  description = "The Resource Group ID declared in the root module and passed to budgets"
}