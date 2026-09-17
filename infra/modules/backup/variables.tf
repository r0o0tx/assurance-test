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

variable "jobs_subnet_id" {
  type = string
}

variable "deployer_ip_rules" {
  type        = list(string)
  default     = []
  description = "Public IP(s) allowed on the backup storage data plane so the identity running an apply can manage the container. Set to the runner/local IP at deploy time."
}

variable "identity_id" {
  type = string
}

variable "identity_client_id" {
  type = string
}

variable "identity_principal_id" {
  type = string
}

variable "acr_login_server" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "law_workspace_id" {
  type        = string
  description = "Log Analytics workspace GUID; ships the backup container logs off-box for alerting."
}

variable "law_workspace_key" {
  type      = string
  sensitive = true
}
