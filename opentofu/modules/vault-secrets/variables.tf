variable "proxmox_credentials_path" {
  description = "Percorso in Vault dove sono memorizzate le credenziali Proxmox"
  type        = string
  default     = "terraform/data/proxmox/api_credentials"
}

variable "ssh_keys_path" {
  description = "Percorso in Vault dove sono memorizzate le chiavi SSH"
  type        = string
  default     = "terraform/data/ssh_keys/ubuntu"
}

variable "vault_retry" {
  description = "Numero di tentativi di recupero dei segreti in caso di errore"
  type        = number
  default     = 3
}
