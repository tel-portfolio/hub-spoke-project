# Root main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Main Hub Resource Group
resource "azurerm_resource_group" "main_hub" {
  name     = var.resource_group_name
  location = var.location
}

# Main Hub VNET
module "networking" {
  source         = "./modules/networking"
  resource_group_name = var.resource_group_name
  location = var.location
}

# Network Virtual Appliance (NVA)
module "nva" {
  source         = "./modules/nva"
  resource_group_name = var.resource_group_name
  location = var.location

  # WAN and LAN subents for NVA NICs
  wan_subnet_id = module.networking.wan_subnet_id
  lan_subnet_id = module.networking.lan_subnet_id
}

# Vnet Spoke01 for peering to Hub
module "spoke" {
 source = "./modules/spoke"
 resource_group_name = var.resource_group_name
}

# UDRs for Spoke to NVA traffic
module "routing" {
  source = "./modules/routing"
  resource_group_name = var.resource_group_name
}

# Budget Notifications
module "budget" {
  source = "./modules/budget"
  resource_group_name = var.resource_group_name
  resource_group_id = azurerm_resource_group.main_hub.id
}