# modules/networking/main.tf

resource "azurerm_virtual_network" "hub_vnet" {
  name           = "hub"
  location       = var.location
  resource_group_name = var.resource_group_name
  address_space  = ["10.0.0.0/16"]
}

# For WAN traffic
resource "azurerm_subnet" "wan_subnet" {
  name                 = "snet-hub-wan"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# For LAN traffic
resource "azurerm_subnet" "lan_subnet" {
  name                 = "snet-hub-lan"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# For Bastion/Jumpbox
resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = "snet-hub-jumpbox"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}