variable "location" {
  type    = string
  default = "eastus"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment slug (dev/staging/prod); drives the resource group name and tags."
}

variable "resource_group" {
  type        = string
  default     = null
  description = "Override the resource group name; defaults to rg-assurance-test-<env>-aks."
}

variable "prefix" {
  type    = string
  default = "asttk"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "db_sku" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "high_availability_enabled" {
  type        = bool
  default     = true
  description = "Zone-redundant database HA; turn off for a cheaper dev stack."
}

# Shared container registry that already holds the web/api images.
variable "acr_name" {
  type        = string
  description = "Name of the existing ACR holding web/api images (e.g. from ../infra output acr_name)."
}

variable "acr_resource_group" {
  type    = string
  default = "rg-assurance-test-prod"
}

variable "web_tag" {
  type    = string
  default = "bootstrap"
}

variable "api_tag" {
  type    = string
  default = "bootstrap"
}

