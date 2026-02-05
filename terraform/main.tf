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
  name = "rg-hub-spoke-portfolio"
  location = var.location
}

# Main Hub VNET
module "hub_vnet" {
  source              = "./modules/hub"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location
}

# Define Log Analytics Workspace.
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location
}

# Network Virtual Appliance (NVA)
module "nva" {
  source              = "./modules/nva"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location

  # WAN and LAN subents for NVA NICs
  wan_subnet_id = module.hub_vnet.wan_subnet_id
  lan_subnet_id = module.hub_vnet.lan_subnet_id

  # Connect the Log Analytics Workspace
  log_analytics_workspace_id = module.monitoring.workspace_id
}

# Routing UDRs for Spoke to NVA traffic
module "routing" {
  source              = "./modules/routing"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location

  # Connect the NVA's IP to the Router
  nva_lan_ip = module.nva.nva_lan_ip
}

# Budget Notifications
module "budget" {
  source              = "./modules/budget"
  resource_group_name = azurerm_resource_group.main_hub.name
  resource_group_id   = azurerm_resource_group.main_hub.id
}

# Vnet Algo Spoke for peering to Hub
module "algo_spoke" {
  source              = "./modules/spoke"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location

  # Id of Route Table to be associated with the spoke subnet
  route_table_id = module.routing.route_table_id
}

# Peering 1: Hub-to-Spoke (Allow Hub to see Algo-Spoke)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-algospoke"
  resource_group_name = azurerm_resource_group.main_hub.name
  virtual_network_name      = module.hub_vnet.hub_vnet_name
  remote_virtual_network_id = module.algo_spoke.vnet_id
  allow_forwarded_traffic   = true
}

# Peering 2: Spoke-to-Hub (Allow Algo-Spoke to see Hub)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-algospoke-to-hub"
  resource_group_name = azurerm_resource_group.main_hub.name
  virtual_network_name      = module.algo_spoke.vnet_name
  remote_virtual_network_id = module.hub_vnet.hub_vnet_id
  allow_forwarded_traffic   = true
}

