variable "proxmox_host" {
  default = "pve"
}

variable "template_name" {
  default = "debian13-cloudinit"
}

variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}
