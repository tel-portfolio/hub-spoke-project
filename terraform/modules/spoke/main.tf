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
  name                 = "algo-workload"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.algo_spoke.name
  address_prefixes     = ["10.1.0.0/24"]
}

# Associate the Route Table to the spoke subnet
resource "azurerm_subnet_route_table_association" "rt_spoke_association" {
  subnet_id      = azurerm_subnet.algo_workload.id
  route_table_id = var.route_table_id
}

# NSGs to allow SSH from Hub ONLY and allow traffic to the internet
resource "azurerm_network_security_group" "algo_spoke_nsg" {
  name                = "algo-spoke-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  #Allow SSH from Hub Vnet
  security_rule {
    name                       = "Allow SSH From Hub Vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = ["10.0.0.0/16"]
    destination_address_prefix = "*"
  }

  # Allow traffic to public internet
  security_rule {
    name                       = "Allow-Internet-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443" # HTTPS only
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

#Attache Network Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_spoke_association" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.algo_spoke_nsg.id
}