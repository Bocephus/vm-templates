variable "proxmox_url" {
  type    = string
  default = env("PROXMOX_URL")
}

variable "proxmox_api_token_id" {
  type    = string
  default = env("PROXMOX_API_TOKEN_ID")
}

variable "proxmox_api_token_secret" {
  type      = string
  default   = env("PROXMOX_API_TOKEN_SECRET")
  sensitive = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node to build the template on — the short cluster node name (see `pvecm nodes` or `/etc/pve/nodes/`), not the FQDN"
}

variable "proxmox_insecure_skip_tls_verify" {
  type    = bool
  default = false
}

variable "iso_file" {
  type        = string
  description = "Proxmox storage path to the Ubuntu Server ISO, e.g. local:iso/ubuntu-24.04.2-live-server-amd64.iso"
}

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

variable "vm_storage_pool" {
  type        = string
  description = "Storage pool for the built VM's disks"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "template_name" {
  type    = string
  default = "tpl-ubuntu-2404"
}

variable "template_id" {
  type        = number
  description = "Proxmox VMID for the resulting template"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "ssh_username" {
  type    = string
  default = "ansible"
}

variable "ssh_password" {
  type      = string
  default   = "packer"
  sensitive = true
  description = "Temporary password set via autoinstall; the account is only used for the duration of the build"
}
