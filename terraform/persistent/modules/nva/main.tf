# modules/nva/main.tf

resource "azurerm_linux_virtual_machine" "nva" {
  name                = "nva-linux-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"

  # NICs
  network_interface_ids = [
    azurerm_network_interface.wan_nic.id,
    azurerm_network_interface.lan_nic.id
  ]

  # Image Block
source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  #Virtual Disk
os_disk {
    name                 = "osdisk-nva"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  # SSH Credentials
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub") # Ensure this path points to your local public key
  }

  #Bootstrapping Ubuntu Script
  custom_data = filebase64("${path.module}/../../scripts/bash/ubuntu-firewall-setup.sh")

  boot_diagnostics {}
}

# WAN NIC
resource "azurerm_network_interface" "wan_nic" {
  name                = "wan"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_forwarding_enabled = true # I will delete this once I can get Bastion Free SKU working but need it for now.

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


resource "azurerm_network_security_group" "nva_wan_nsg" {
  name                = "nsg-nva-wan"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH from ANYWHERE (for now) to ensure you can get in.
  security_rule {
    name                       = "Whitelist-IP-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"

    # Workaround - Whitelist my IP dynamically
    source_address_prefix = "${var.whitelist_ip}/32"
    destination_address_prefix = "*"
  }
}

# 2. ATTACH the NSG to the WAN NIC (Critical Step)
resource "azurerm_network_interface_security_group_association" "nva_wan_assoc" {
  network_interface_id      = azurerm_network_interface.wan_nic.id
  network_security_group_id = azurerm_network_security_group.nva_wan_nsg.id
}