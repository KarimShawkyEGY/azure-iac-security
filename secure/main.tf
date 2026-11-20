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

# SECURE STORAGE: no public blobs, HTTPS only, modern TLS
resource "azurerm_storage_account" "data" {
  name = "iaclabstorage123"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled = true
  min_tls_version = "TLS1_2"
}

# SECURE NSG: SSH limited to a trusted admin IP, no RDP from internet
resource "azurerm_network_security_group" "nsg" {
  name = "nsg-iac-lab"
  location = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name = "allow-ssh-admin"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "203.0.113.10/32"
    destination_address_prefix = "*"
  }
} 

# SECURE SQL: password from a variable, firewall not open to the internet
resource "azurerm_mssql_server" "sql" {
  name = "iac-lab-sql"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  version = "12.0"
  administrator_login = "sqladmin"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version = "1.2"
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  name = "allow-azure-services"
  server_id = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address = "0.0.0.0"
}

# SECURE KEY VAULT: purge protection on, public network access off
resource "azurerm_key_vault" "kv" {
  name = "iac-lab-kv"
  location = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tenant_id = "00000000-0000-0000-0000-000000000000"
  sku_name = "standard"
  purge_protection_enabled = true
  public_network_access_enabled = false
}
