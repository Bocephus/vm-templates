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
  description = "Proxmox node to build the template on"
}

variable "proxmox_insecure_skip_tls_verify" {
  type    = bool
  default = false
}

variable "iso_file" {
  type        = string
  description = "Proxmox storage path to the Windows Server 2025 install ISO"
}

variable "virtio_win_iso_file" {
  type        = string
  description = "Proxmox storage path to the virtio-win driver ISO, e.g. local:iso/virtio-win.iso"
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
  default = "tpl-windows-server-2025"
}

variable "template_id" {
  type        = number
  description = "Proxmox VMID for the resulting template"
}

variable "disk_size" {
  type    = string
  default = "60G"
}

variable "cores" {
  type    = number
  default = 4
}

variable "memory" {
  type    = number
  default = 4096
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type        = string
  sensitive   = true
  default     = "P@ckerBuild!2025"
  description = "Local Administrator password — must match answer_files/Autounattend.xml"
}
