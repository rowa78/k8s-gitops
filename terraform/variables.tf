variable "PROXMOX_API_HOST" {
  description = "The URL of the Proxmox API"
  type        = string
}


variable "ssh_public_key" {
  description = "Public SSH key for cloud-init"
}

variable "vm_definitions" {
  description = "Map of Master definitions"
  type        = map(object({
    vmid       = number
    name       = string
    node       = string
    cores      = number
    memory     = number
    balloon    = number
    disk_size  = string
    ipconfig0  = string
    startupid  = string
    tags       = string
  }))
}
