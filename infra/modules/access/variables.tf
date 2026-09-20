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

variable "vnet_id" {
  type        = string
  description = "Virtual network the Developer Bastion attaches to."
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name, used to place the showcase subnet."
}

variable "vnet_cidr" {
  type        = string
  description = "Address space the subnet router advertises to the tailnet."
}

variable "bastion_enabled" {
  type        = bool
  default     = false
  description = "Deploy a Developer SKU Bastion for break-glass SSH to the private nodes. Free, no public IP, no dedicated subnet."
}

variable "tailscale_enabled" {
  type        = bool
  default     = false
  description = "Deploy the Tailscale subnet-router VM. Showcase only: off by default and never a primary access path."
}

variable "tailscale_subnet_cidr" {
  type        = string
  default     = "10.40.5.0/24"
  description = "Dedicated subnet for the showcase subnet-router VM."
}

variable "tailscale_auth_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Tailscale auth key for the subnet router. Source it from Key Vault or a CI secret; never commit it."
}

variable "tailscale_vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the showcase VM's admin user."
}
