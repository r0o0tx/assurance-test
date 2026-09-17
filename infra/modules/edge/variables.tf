variable "rg" {
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

variable "location" {
  type = string
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "web_origin_host" {
  type        = string
  description = "Private IP / host header of the web tier internal load balancer."
}

variable "api_origin_host" {
  type        = string
  description = "Private IP / host header of the api tier internal load balancer."
}

variable "web_pls_id" {
  type        = string
  description = "Private Link Service fronting the web internal load balancer."
}

variable "api_pls_id" {
  type        = string
  description = "Private Link Service fronting the api internal load balancer."
}
