# modules/nva/main.tf

resource "azurerm_linux_virtual_machine" "nva" {
  name                = "nva-opnsense-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  vm_size             = "Standard_B2s"

  # NICs
  network_interface_ids = [
    azurerm_network_interface.wan_subnet_id.id,
    azurerm_network_interface.lan_subnet_id.id
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
