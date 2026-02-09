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

# Get my personal IP address for whitelisting, When Bastion free SKU starts working again I can delete this but this but neccessary for now.

data "http" "whitelist_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Main Hub Resource Group
resource "azurerm_resource_group" "main_hub" {
  name     = "rg-hub-spoke-portfolio"
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

  # My Whitelisted IP
  whitelist_ip = chomp(data.http.whitelist_ip.response_body)
}

# Management, Bastion and Jumpbox VM (Using NVA for now until Bastion Free SKU works again.)
# module "management" {
#   source              = "./modules/management"
#   resource_group_name = azurerm_resource_group.main_hub.name
#   location            = var.location

#   #Connect Bastion and Jumpbox to Hub VNet
#   hub_vnet_id       = module.hub_vnet.hub_vnet_id
#   jumpbox_subnet_id = module.hub_vnet.jumpbox_subnet_id

#   #Login creds and LAN IP for Jumpbox to bootstrap NVA
#   nva_username = module.nva.nva_username
#   nva_lan_ip   = module.nva.nva_lan_ip

#   #Wait for NVA to provision for bootstrapping
#   depends_on = [module.nva]

#     # My Whitelisted IP
#   whitelist_ip = chomp(data.http.whitelist_ip.response_body)
# }

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
  source              = "./modules/spoke-compute"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location

  # Id of Route Table to be associated with the spoke subnet
  route_table_id = module.routing.route_table_id
}

#Vnet for Data Spoke for peering to Hub
module "data_spoke" {
  source              = "./modules/spoke-data"
  resource_group_name = azurerm_resource_group.main_hub.name
  location            = var.location
}

# Peering 1: Hub-to-Spoke (Allow Hub to see Algo-Spoke)
resource "azurerm_virtual_network_peering" "hub_to_spoke_compute" {
  name                      = "peer-hub-to-algospoke"
  resource_group_name       = azurerm_resource_group.main_hub.name
  virtual_network_name      = module.hub_vnet.hub_vnet_name
  remote_virtual_network_id = module.algo_spoke.vnet_id
  allow_forwarded_traffic   = true
}

# Peering 2: Spoke-to-Hub (Allow Algo-Spoke to see Hub)
resource "azurerm_virtual_network_peering" "spoke_compute_to_hub" {
  name                      = "peer-algospoke-to-hub"
  resource_group_name       = azurerm_resource_group.main_hub.name
  virtual_network_name      = module.algo_spoke.vnet_name
  remote_virtual_network_id = module.hub_vnet.hub_vnet_id
  allow_forwarded_traffic   = true
}

