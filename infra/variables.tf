variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment (dev, staging, prod). Drives the RG name, tags, and state key."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "subscription_id" {
  type        = string
  default     = ""
  description = "Target subscription. Empty uses the CLI default; set per-env for multi-subscription separation."
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group" {
  type        = string
  default     = null
  description = "Override the resource group name. Defaults to rg-<name_prefix>-<environment>."
}

variable "name_prefix" {
  type    = string
  default = "assurance-test"
}

variable "short_prefix" {
  type    = string
  default = "astst"
}

variable "web_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "api_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "web_instance_count" {
  type    = number
  default = 2
}

variable "api_instance_count" {
  type    = number
  default = 2
}

variable "vm_sku" {
  type    = string
  default = "Standard_B2s"
}

variable "db_sku" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "high_availability_enabled" {
  type        = bool
  default     = true
  description = "Zone-redundant DB HA. Enable in prod; disable in dev/staging to reduce cost (needs a General Purpose db_sku)."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VMSS admin (management fallback; password auth disabled)."
}

variable "alert_email" {
  type        = string
  default     = ""
  description = "Operational alert destination. Empty (default) disables the action group and all alert rules; set per environment to enable."
}

variable "deployer_ip_rules" {
  type        = list(string)
  default     = []
  description = "Public IP(s) of the identity running the apply, allowed on the network-restricted Key Vault and backup storage data planes. CI sets this to the runner IP; set your own IP for a local apply."
}

variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable Key Vault purge protection. Set true in prod/staging; false in dev for easy teardown."
}

variable "log_daily_quota_gb" {
  type        = number
  default     = -1
  description = "Log Analytics daily ingestion cap in GB (-1 = uncapped). Set per environment to bound monitoring cost; lower tiers use a tighter cap."
}

variable "rbac_enabled" {
  type        = bool
  default     = false
  description = "Provision the Entra role groups, scoped custom roles, and the database Entra admin. Off by default: enabling it requires the deploying identity to hold Microsoft Graph Group.ReadWrite.All (admin-consented), so it is typically applied locally under an Entra directory admin."
}

variable "bastion_enabled" {
  type        = bool
  default     = false
  description = "Deploy a Developer SKU Bastion for break-glass SSH to the private nodes. Free, no public IP. Enabled in prod/staging."
}

variable "tailscale_enabled" {
  type        = bool
  default     = false
  description = "Deploy the Tailscale subnet-router VM. Showcase only: off by default and never a primary access path."
}

variable "tailscale_auth_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Tailscale auth key for the showcase subnet router; source from Key Vault or a CI secret, never commit."
}
