# modules/ spoke/main.tf

#S Spoke01 Vnet (10.1.0.0)
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" {
    name = "algo-workload"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.spoke.name
    address_space = ["10.1.0.0/24"]
}