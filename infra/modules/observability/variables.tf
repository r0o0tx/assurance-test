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

variable "identity_principal_id" {
  type = string
}

variable "web_vmss_id" {
  type = string
}

variable "api_vmss_id" {
  type = string
}

variable "frontdoor_profile_id" {
  type = string
}

variable "web_lb_id" {
  type = string
}

variable "api_lb_id" {
  type = string
}

variable "db_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "frontdoor_endpoint_host" {
  type        = string
  description = "Public Front Door hostname, probed by the synthetic availability test."
}

variable "alert_email" {
  type        = string
  description = "Destination for operational alerts. Empty disables the action group and all alert rules."
  default     = ""
}
