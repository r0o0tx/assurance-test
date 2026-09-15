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

variable "app_port" {
  type    = number
  default = 3000
}

variable "vm_sku" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "identity_id" {
  type = string
}

variable "identity_client_id" {
  type = string
}

variable "acr_login_server" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "web_subnet_id" {
  type = string
}

variable "api_subnet_id" {
  type = string
}

variable "api_internal_ip" {
  type    = string
  default = "10.40.2.10"
}

variable "web_instance_count" {
  type = number
}

variable "api_instance_count" {
  type = number
}

variable "web_image_tag" {
  type = string
}

variable "api_image_tag" {
  type = string
}
