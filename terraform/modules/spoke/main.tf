# modules/spoke/main.tf

# Algo-Spoke Vnet (10.1.0.0)
resource "azurerm_virtual_network" "algo_spoke" {
  name                = "algo-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

# Define Algo Spoke subnet
resource "azurerm_subnet" "algo_workload" {
    name = "algo-workload"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.algo_spoke.name
    address_prefixes = ["10.1.0.0/24"]
}

# Associate the Route Table to the spoke subnet
resource "azurerm_subnet_route_table_association" "spoke_association" {
  subnet_id      = azurerm_subnet.algo_workload.id
  route_table_id = var.route_table_id
}