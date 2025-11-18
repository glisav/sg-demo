output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_names" {
  description = "List of created database names"
  value       = [for db in azurerm_postgresql_flexible_server_database.databases : db.name]
}

output "admin_username" {
  description = "Administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "connection_string_key_vault" {
  description = "Key Vault name where connection string is stored"
  value       = azurerm_key_vault.main.name
}

output "connection_string_secret_name" {
  description = "Name of the secret containing the connection string"
  value       = azurerm_key_vault_secret.connection_string.name
}

output "server_version" {
  description = "PostgreSQL server version"
  value       = azurerm_postgresql_flexible_server.main.version
}

output "location" {
  description = "Azure region where resources were deployed"
  value       = azurerm_resource_group.main.location
}

output "tags" {
  description = "Tags applied to the resources"
  value       = local.common_tags
}
