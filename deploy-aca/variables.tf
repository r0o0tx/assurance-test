variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group" {
  type    = string
  default = "rg-assurance-test-aca"
}

variable "prefix" {
  type    = string
  default = "asttc"
}

variable "acr_name" {
  type        = string
  description = "Name of the existing ACR holding web/api images."
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
    env        = "aca"
    managed-by = "terraform"
    owner      = "shubham"
  }
}
