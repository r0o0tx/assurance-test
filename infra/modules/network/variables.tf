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

variable "app_port" {
  type    = number
  default = 3000
}

variable "vnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "web_subnet_cidr" {
  type    = string
  default = "10.40.1.0/24"
}

variable "api_subnet_cidr" {
  type    = string
  default = "10.40.2.0/24"
}

variable "db_subnet_cidr" {
  type    = string
  default = "10.40.3.0/24"
}

variable "jobs_subnet_cidr" {
  type    = string
  default = "10.40.4.0/24"
}
