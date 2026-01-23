resource "azurerm_virtual_network" "hub_vnet" {
  name = "hub"
  location = var.location
  resource_group = azurerm_resource_group.hub_rg.name
  address_space       = ["10.0.0.0/16"]

  # For WAN traffic
  subnet {
    name = "snet-hub-wan"
  }

  # For LAN traffic
  subnet {
    name = "snet-hub-lan"

  }
  
  # For Bastion/Jumpbox
  subnet {
    name = "snet-hub-jumpbox"
  }

}


