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
  name     = "rg_main_hub"
  location = var.location
}

# Main Hub VNET
module "networking" {
  source = "./modules/networking"
  resource_group = azurerm_resource_group.main_hub.name
}

# Network Virtual Appliance (NVA)
module "nva" {
  source = "./nva/nva"
  resource_group = azurerm_resource_group.main_hub.name
}