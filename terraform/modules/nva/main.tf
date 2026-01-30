# modules/nva/main.tf

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
    version   = "25.1.3"
  }

  #Virtual Disk
  os_disk {
    name                 = "osdisk-nva"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # SSH Credentials
  admin_username                  = "azureuser"
  disable_password_authentication = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
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

# Install Azure Monitor Agent for Linux on NVA
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.nva.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}