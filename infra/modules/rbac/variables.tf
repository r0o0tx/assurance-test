variable "rg_id" {
  type        = string
  description = "Resource group scope for the role assignments and custom role definitions."
}

variable "rg_name" {
  type        = string
  description = "Resource group name (used to set the database Entra administrator)."
}

variable "short_prefix" {
  type        = string
  description = "Naming prefix shared with the rest of the environment."
}

variable "environment" {
  type        = string
  description = "Environment slug (dev/staging/prod) used in group and role names."
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant hosting the role groups."
}

variable "db_server_name" {
  type        = string
  description = "PostgreSQL flexible server name that the dba group administers."
}
