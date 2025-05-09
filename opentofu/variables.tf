# Configurazione Vault
variable "vault_addr" {
  description = "HashiCorp Vault API address"
  type        = string
  default     = "http://vault:8200"
}

variable "vault_proxmox_credentials_path" {
  description = "Path in Vault per le credenziali Proxmox"
  type        = string
  default     = "terraform/proxmox/api_credentials"
}

variable "vault_ssh_keys_path" {
  description = "Path in Vault per le chiavi SSH"
  type        = string
  default     = "terraform/ssh_keys/ubuntu"
}

variable "vault_retry" {
  description = "Numero di tentativi di recupero dei segreti in caso di errore"
  type        = number
  default     = 3
}

# Autenticazione Vault AppRole
variable "vault_approle_enabled" {
  description = "Abilitare l'autenticazione AppRole per Vault"
  type        = bool
  default     = false
}

variable "vault_approle_role_id" {
  description = "Role ID per l'autenticazione AppRole di Vault"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vault_approle_secret_id" {
  description = "Secret ID per l'autenticazione AppRole di Vault"
  type        = string
  default     = ""
  sensitive   = true
}

# Configurazione Proxmox
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_insecure" {
  description = "Skip SSL verification per Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_timeout" {
  description = "Timeout per le connessioni Proxmox API"
  type        = number
  default     = 300
}

variable "proxmox_auth_ticket" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_csrf_prevention_token" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_token_auth" {
  description = "Utilizza l'autenticazione token invece di username/password per Proxmox"
  type        = bool
  default     = false
}

# Configurazione Globale VM/LXC
variable "default_node" {
  description = "Nodo Proxmox predefinito per le VM e i container"
  type        = string
}

variable "default_datastore" {
  description = "Datastore predefinito per le VM e i container"
  type        = string
  default     = "local-lvm"
}

variable "iso_datastore" {
  description = "Datastore per le immagini ISO"
  type        = string
  default     = "iso"
}

variable "snippets_datastore_id" {
  description = "Datastore per gli snippet cloud-init"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Bridge di rete predefinito per le VM e i container"
  type        = string
  default     = "vmbr0"
}

# Configurazioni globali
variable "default_user" {
  description = "Nome utente SSH predefinito per le VM"
  type        = string
  default     = "filippo"
}

variable "default_timezone" {
  description = "Fuso orario predefinito per le VM"
  type        = string
  default     = "Europe/Rome"
}

variable "default_locale" {
  description = "Locale predefinito per le VM"
  type        = string
  default     = "it_IT.UTF-8"
}

# Configurazioni container LXC
variable "default_lxc_template" {
  description = "Template LXC predefinito da utilizzare"
  type        = string
  default     = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

