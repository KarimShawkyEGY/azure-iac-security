terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}	

provider "azurerm" {
  feature {}
}

resource "azurerm_resource_group" "lab" {
  name = "rg-iac-lab"
  location = "West Europe"
}

# INSECURE STORAGE: public blobs, plain HTTP allowed, weak TLS
resource "azurerm_storage_account" "data" {
  name = "iaclabstorage123"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled = false
  min_tls_version = "TLS1_0"
}

# INSECURE NSG: SSH (Port 22) and RDP (Port 3389) open to the whole internet
resource "azurerm_network_security_group" "nsg" {
  name = "nsg-iac-lab"
  location = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name = "allow-ssh"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "allow-rdp"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# INSECURE SQL: hardcoded password (secret in code) + firewall open to all
resource "azurerm_mssql_server" "sql" {
  name = "iac-lab-sql"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  version = "12.0"
  administrator_login = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"
}

resource "azurerm_mssql_firewall_rule" "allow_all" {
  name = "allow-all"
  server_id = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address = "255.255.255.255"
}

# INSECURE KEY VAULT: purge protection off, public network access on
resource "azurerm_key_vault" "kv" {
  name = "iac-lab-kv"
  location = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tenant_id = "00000000-0000-0000-0000-000000000000"
  sku_name = "standard"
  purge_protection_enabled = false
  public_network_access_enabled = true
}

















