# modules/data-spoke/main.tf

# Add the virtual network
resource "azurerm_virtual_network" "spoke_data" {
  name                = "data-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.2.0.0/16"]
}

# ---------- Key Vault ----------

#Give myself permisson to add keys
data "azurerm_client_config" "current" {}

# Random suffix for KV name
resource "random_id" "kvault_suffix" {
  byte_length = 4
}
# Provision Key Vault
resource "azurerm_key_vault" "kvault" {
  name                        = "kv-hub-${random_id.kvault_suffix.hex}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"

  # Access Policy to allow myself to add and delete objects
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

# ---------- Key Vault Networking ----------

#Define Azure Keyvault subnet
resource "azurerm_subnet" "kvault_subnet" {
  name                 = "key-vault"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_data.name
  address_prefixes     = ["10.2.0.0/24"]

  #Service endpoint to keep traffic on Microsoft Backbone network
  service_endpoints = ["Microsoft.KeyVault"]
}

#Define Key Vault NSG to deny all traffic from the internet
resource "azurerm_network_security_group" "spoke_data_nsg" {
  name                = "spoke-data-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  #Allow traffic to internet for keyvault only (needs to do this for Azure backbone)
  security_rule {
    name                       = "Allow-Azure-KeyVault"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureKeyVault" # Service Tag magic
  }

  # Deny traffic from public internet
  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  # Deny traffice to public internet
  security_rule {
    name                       = "Deny-Internet-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

#Attache Network Rule to Subnet
resource "azurerm_subnet_network_security_group_association" "data_spoke_nsg_association" {
  subnet_id                 = azurerm_subnet.kvault_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_data_nsg.id
}

# Upload the SSH key
resource "azurerm_key_vault_secret" "ssh_key" {
  name = "ssh-key-twoolsey"

  # Read id_rsa.pem from keys/ directory
  value = file("${path.root}/keys/id_rsa.pem")

  key_vault_id = azurerm_key_vault.kvault.id

  # Terraform must wait for the Access Policy to exist
  depends_on = [azurerm_key_vault.kvault]
}
