variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group" {
  type    = string
  default = "rg-assurance-test-prod"
}

variable "name_prefix" {
  type    = string
  default = "assurance-test"
}

variable "short_prefix" {
  type    = string
  default = "astst"
}

variable "web_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "api_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "web_instance_count" {
  type    = number
  default = 2
}

variable "api_instance_count" {
  type    = number
  default = 2
}

variable "vm_sku" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "db_sku" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VMSS admin (management fallback; password auth disabled)"
}

variable "tags" {
  type = map(string)
  default = {
    app        = "assurance-test"
    env        = "prod"
    managed-by = "terraform"
    owner      = "shubham"
  }
}
