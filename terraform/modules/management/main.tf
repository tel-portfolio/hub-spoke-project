# modules/management.main.tf

#Deploy Bastion Developer version
resource "azurerm_bastion_host" "bastion_main" {
  name                = "bastion-hub-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Developer"
  virtual_network_id  = var.hub_vnet_id
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
    username   =  "twoolsey"
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
}