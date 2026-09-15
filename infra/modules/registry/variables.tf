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

variable "vmss_principal_id" {
  type        = string
  description = "Principal ID of the VMSS managed identity (granted AcrPull)."
}
