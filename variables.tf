variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters, lowercase letters, numbers, and hyphens only."
  }
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "West Europe"
}

variable "database_names" {
  description = "List of database names to create"
  type        = list(string)
  default     = ["app_db"]
  validation {
    condition     = length(var.database_names) > 0 && length(var.database_names) <= 5
    error_message = "Must specify between 1 and 5 database names."
  }
}

variable "sku_name" {
  description = "SKU for PostgreSQL server"
  type        = string
  default     = "B_Standard_B1ms"
  validation {
    condition = contains([
      "B_Standard_B1ms",
      "B_Standard_B2s",
      "GP_Standard_D2s_v3",
      "GP_Standard_D4s_v3"
    ], var.sku_name)
    error_message = "SKU must be a valid PostgreSQL Flexible Server SKU."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "pgadmin"
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{2,15}$", var.admin_username))
    error_message = "Username must be 3-16 characters, start with letter, contain only lowercase letters, numbers, and underscores."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
