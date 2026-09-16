variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group" {
  type    = string
  default = "rg-assurance-test-aks"
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

variable "tags" {
  type = map(string)
  default = {
    app        = "assurance-test"
    env        = "aks"
    managed-by = "terraform"
    owner      = "shubham"
  }
}
