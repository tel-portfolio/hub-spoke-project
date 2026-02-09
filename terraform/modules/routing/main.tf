# modules/routing/main.tf

# Define Route Table
resource "azurerm_route_table" "route_table_spoke_compute" {
  name                = "rt-spoke-compute-to-nva"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Force Traffic to NVA
resource "azurerm_route" "default_to_nva" {
  name                   = "rt-default-0-0-0-0"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.route_table_spoke_compute.name
  address_prefix         = "0.0.0.0/0" #Catches everything outbound to the public internet
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.nva_lan_ip
}