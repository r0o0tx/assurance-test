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

variable "web_origin_host" {
  type        = string
  description = "Public FQDN of the web tier load balancer."
}

variable "api_origin_host" {
  type        = string
  description = "Public FQDN of the api tier load balancer."
}
