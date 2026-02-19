# modules/acr/main.tf

# ACR
resource "azurerm_container_registry" "acr" {
    name = "acralgotradebot01"
    resource_group_name = var.resource_group_name
    location = var.location
    sku = "Basic"
    admin_enabled = false
}