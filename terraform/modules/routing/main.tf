# modules/routing/main.tf

# Define Route Table
resource "azurerm_route_table" "route_table_spoke" {
  name                = "rt-spoke-to-nva"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Force Traffic to NVA
resource "azurerm_route" "default_to_nva" {
  name                   = "rt-default-0-0-0-0"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.rt_spoke.name
  address_prefix         = "0.0.0.0/0" #Catches everything
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.nva_lan_ip
}

# Associate Route Table subnet
resource "azurerm_subnet_route_table_association" "spoke_assoc" {
  subnet_id      = var.subnet_id_to_associate
  route_table_id = azurerm_route_table.route_table_spoke.id
}