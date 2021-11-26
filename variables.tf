variable "connection" {
  description = "Map of connection credentials to Proxmox VE"
  type        = map(any)
  default     = {}
}

variable "vms" {
  description = "Map of virtual machines"
  type        = map(any)
  default     = {}
}

