variable "rg" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "short_prefix" {
  type = string
}

variable "suffix" {
  type = string
}

variable "db_sku" {
  type = string
}

variable "high_availability_enabled" {
  type    = bool
  default = true
}

variable "db_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "entra_auth_enabled" {
  type        = bool
  default     = false
  description = "Enable Entra ID authentication on the server alongside password auth, so an Entra group can be set as the database administrator."
}

variable "tenant_id" {
  type        = string
  default     = ""
  description = "Entra tenant for Entra ID authentication; required when entra_auth_enabled is true."
}
