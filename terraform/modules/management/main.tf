# modules/management.main.tf

#Deploy Bastion Developer version (Cutting bastion out until there is a fix in the outtage)
# resource "azurerm_bastion_host" "bastion_main" {
#   name                = "bastion-hub-dev"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku                 = "Developer"
#   virtual_network_id  = var.hub_vnet_id
# }

# Alternative to Bastion, Whitelist my IP into the Jumpbox
data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

#Add NIC to Jumpbox
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "jump_hub_nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Provision Jumpbox
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = "vm-jumpbox-01"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = "Standard_B1s"
  admin_username        = "twoolsey"
  network_interface_ids = [azurerm_network_interface.jumpbox_nic.id]

  # Use SSH key to access Jumpbox
  disable_password_authentication = true
  admin_ssh_key {
    username   = "twoolsey"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Make sure the jumpbox is booting properly
  boot_diagnostics {}
}

# --- Jumpbox Security ---

#Create the NSG to allow traffic on port 22 from bastion developer version
resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "nsg-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name

  #Allow Azure Bastion to connect to Jumpbox
  security_rule {
    name                       = "Whitelist-IP-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"

    # source_address_prefix      = "GatewayManager"  # GatewayManager is the service tag for Bastion traffic (disable until bastion outtage resolves)

    # Workaround - Whitelist my IP dynamically
    source_address_prefix      = "${chomp(data.http.my_public_ip.response_body)}/32"
    destination_address_prefix = "*"
  }

  # Deny everything else
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Attach the NSG to the Jumpbox NIC
resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}