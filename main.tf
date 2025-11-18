terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random password for PostgreSQL admin
resource "random_password" "admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Local values for consistent naming
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Stackguardian"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  })
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "postgres-${local.resource_prefix}"
  resource_group_name    = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  version               = "14"
  administrator_login    = var.admin_username
  administrator_password = random_password.admin_password.result
  sku_name              = var.sku_name
  storage_mb            = 32768

  backup_retention_days = var.backup_retention_days
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false

  tags = local.common_tags
}

# PostgreSQL Configuration
resource "azurerm_postgresql_flexible_server_configuration" "timezone" {
  name      = "timezone"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "UTC"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "all"
}

# Firewall rule for Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create databases
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.database_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}

# Key Vault for storing connection string
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.resource_prefix}-${random_password.admin_password.bcrypt_hash[0:8]}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "List"
    ]
  }

  tags = local.common_tags
}

# Store connection string in Key Vault
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "postgresql-connection-string"
  value        = "postgresql://${var.admin_username}:${random_password.admin_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_names[0]}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}
