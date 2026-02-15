# ---------- Data Sources ----------
data "azurerm_client_config" "current" {}

# ---------- Random Generators ----------
# Random suffix for unique KV naming
resource "random_id" "kvault_suffix" {
  byte_length = 4
}

# Random Password for SQL Admin
resource "random_password" "sql_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ---------- Networking ----------

resource "azurerm_virtual_network" "data_vnet" {
  name                = "vnet-data-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "data_tier" {
  name                 = "snet-data-tier"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.data_vnet.name
  address_prefixes     = ["10.2.1.0/24"]

  # Enable Service Endpoints for KV and SQL (Best practice for hybrid access)
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql"]

  # Enable Private Link policies (Required for Private Endpoints)
  private_endpoint_network_policies = "Enabled"
}

# ---------- Network Security Group (NSG) ----------

resource "azurerm_network_security_group" "data_nsg" {
  name                = "nsg-data-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SQL Traffic (1433) from Hub & Spokes
  security_rule {
    name                       = "Allow-SQL-Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }

  # Allow Key Vault to Azure Backbone
  security_rule {
    name                       = "Allow-Azure-KeyVault-Outbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureKeyVault"
  }
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_assoc" {
  subnet_id                 = azurerm_subnet.data_tier.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

# ---------- Key Vault ----------

resource "azurerm_key_vault" "kvault" {
  name                        = "kv-hub-${random_id.kvault_suffix.hex}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false # Fine to purge for Dev
  sku_name                    = "standard"

  # Access Policy: Give current user full control
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Set", "Get", "List", "Delete", "Purge", "Recover"
    ]
  }

  # Network ACLs
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    
    # Allow the Data Subnet and other trusted subnets
    virtual_network_subnet_ids = [
      azurerm_subnet.data_tier.id,
      var.lan_subnet_id,
      var.spoke_compute_subnet_id
    ]
  }
}

# ---------- Secrets Management ----------

# Store the SQL Admin Password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.kvault.id
  
  # Ensure key vault exists before trying to write database secret
  depends_on = [azurerm_key_vault.kvault]
}

# ---------- Azure SQL Database ----------

resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-hub-${random_id.kvault_suffix.hex}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "twoolsey"
  administrator_login_password = random_password.sql_admin.result
}

resource "azurerm_mssql_database" "db" {
  name           = "algo-trading-db"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
}

# ---------- Private Endpoint for SQL ----------

resource "azurerm_private_endpoint" "private_endpoint_sql" {
  name                = "pe-sql-db"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.data_tier.id

  private_service_connection {
    name                           = "psc-sql-db"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}