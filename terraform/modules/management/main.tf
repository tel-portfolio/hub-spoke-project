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

  # Bootstrap login 
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # --- PHASE 1: HARDENING ---
    
    # 1. Enable Automatic Security Updates
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y sshpass unattended-upgrades
    dpkg-reconfigure -f noninteractive unattended-upgrades

    # 2. Configure SSH Idle Timeout (5 minutes)
    # This disconnects you if you leave the terminal open and walk away.
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 0" >> /etc/ssh/sshd_config
    service ssh restart

    # --- PHASE 2: BOOTSTRAP FIREWALL ---
    
    # Capture Variables
    NVA_IP="${var.nva_lan_ip}"
    NVA_USER="${var.nva_username}"
    NVA_PASS="${var.nva_password}"
    PUB_KEY=$(cat /home/${var.nva_username}/.ssh/authorized_keys)

    # Wait for NVA
    echo "Waiting for NVA at $NVA_IP..."
    for i in {1..30}; do
      ssh-keyscan $NVA_IP >> /root/.ssh/known_hosts 2>/dev/null
      if [ $? -eq 0 ]; then
        echo "NVA is reachable!"
        break
      fi
      sleep 10
    done

    # Inject Key
    sshpass -p "$NVA_PASS" ssh -o StrictHostKeyChecking=no $NVA_USER@$NVA_IP "mkdir -p ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

    # --- PHASE 3: BURN AFTER READING ---
    
    # 3. Security Cleanup
    # Delete the tool used to pass the password
    apt-get remove -y sshpass
    
    # WIPE this script from the disk so the password cannot be recovered
    rm -rf /var/lib/cloud/instances/*
    rm -f /var/log/cloud-init-output.log
    
    # Clear history for this session
    history -c
  EOF
  )
}