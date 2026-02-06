# modules/nva/main.tf

#Create randomized password for logging into the OPNsense VM.
resource "random_password" "nva_password" {
  length           = 20
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  override_special = "!@#%&"
}

resource "azurerm_linux_virtual_machine" "nva" {
  name                = "nva-opnsense-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"

  # NICs
  network_interface_ids = [
    azurerm_network_interface.wan_nic.id,
    azurerm_network_interface.lan_nic.id
  ]

  # Marketplace Contract
  plan {
    name      = "opnsense-be-2019"
    product   = "opnsense"
    publisher = "decisosalesbv"
  }

  # Image Block
  source_image_reference {
    publisher = "decisosalesbv"
    offer     = "opnsense"
    sku       = "opnsense-be-2019"
    version   = "24.1.1"
  }

  #Virtual Disk
  os_disk {
    name                 = "osdisk-nva"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # SSH Credentials
  admin_username                  = "twoolsey" # Used my name but you can use what you like
  disable_password_authentication = false      # Temporarily allow password
  admin_password                  = random_password.nva_password.result

  # Fix: VM provisioning hang
  provision_vm_agent         = false
  allow_extension_operations = false
  # Allow for boot diagnostics to see if something is wrong while booting.
  boot_diagnostics {}
}

# WAN NIC
resource "azurerm_network_interface" "wan_nic" {
  name                = "wan"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "external"
    subnet_id                     = var.wan_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nva_pip.id
  }
}

# LAN NIC
resource "azurerm_network_interface" "lan_nic" {
  name                  = "lan"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.lan_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "nva_pip" {
  name                = "pip-nva-wan"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}
