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

variable "web_subnet_id" {
  type = string
}

variable "api_subnet_id" {
  type = string
}

variable "jobs_subnet_id" {
  type = string
}

variable "deployer_ip_rules" {
  type        = list(string)
  default     = []
  description = "Public IP(s) allowed on the Key Vault data plane so the identity running an apply can read/write secrets. Set to the runner/local IP at deploy time."
}

variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable Key Vault purge protection. On in prod/staging; off in dev for easy teardown."
}
